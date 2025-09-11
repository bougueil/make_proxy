function FindProxyForURL(url,host)

{

    // Access the internet directly for one site
    if (dnsDomainIs(host, "www.example.com")) { return "DIRECT";}

    // No proxy for private (RFC 1918) IP addresses (intranet sites)
    if (isInNet(dnsResolve(host), "10.0.0.0", "255.0.0.0") ||
        isInNet(dnsResolve(host), "172.16.0.0", "255.240.0.0") ||
        isInNet(dnsResolve(host), "192.168.0.0", "255.255.0.0")) {  return "DIRECT";}

    // No proxy for localhost
    if (isInNet(dnsResolve(host), "127.0.0.0", "255.0.0.0"))    return "DIRECT";}

    // Clean-up rule. Everything else uses a proxy. Note semi-colon delimiter between strings.
    return "PROXY 127.0.1.1:7070; PROXY 127.0.0.1:7070; DIRECT";
}