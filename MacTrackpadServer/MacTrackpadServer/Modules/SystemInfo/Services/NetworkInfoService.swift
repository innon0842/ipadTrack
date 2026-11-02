import Foundation
import Darwin

struct NetworkInfoService {
    func localIPv4Address() -> String {
        var address = "알 수 없음"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return address }
        defer { freeifaddrs(ifaddr) }
        var ptr = ifaddr
        while let cur = ptr {
            let ifa = cur.pointee
            if let socketAddress = ifa.ifa_addr,
               socketAddress.pointee.sa_family == UInt8(AF_INET),
               String(cString: ifa.ifa_name) == "en0" {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(socketAddress, socklen_t(socketAddress.pointee.sa_len),
                            &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                address = String(cString: host)
            }
            ptr = cur.pointee.ifa_next
        }
        return address
    }
}
