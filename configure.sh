#!/bin/sh

# Download and install xray
mkdir /tmp/xray
curl -L -H "Cache-Control: no-cache" -o /tmp/xray/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip /tmp/xray/xray.zip -d /tmp/xray
install -m 755 /tmp/xray/xray /usr/local/bin/xray
install -m 755 /tmp/xray/geosite.dat /usr/local/bin/geosite.dat
install -m 755 /tmp/xray/geoip.dat /usr/local/bin/geoip.dat

xray -version
 
# Remove temporary directory
rm -rf /tmp/xray

# xray new configuration
install -d /usr/local/etc/xray
cat << EOF > /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 2234, //$PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "alterId": 0,
            "level": 0,
            "email": "vless@in.com"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
      //  "network": "tcp"
      
      //  "network": "grpc",
      //  "grpcSettings": {
      //    "serviceName": "$VL" 
          
                "network": "ws",
                "security": "none",
                "allowInsecure": false,
                "wsSettings": {            
                    "path": "$VL" 
                }   
                
        }   
     
    } 
    
    
  ],
  
"routing": {
  "rules": [
    {
      "type": "field",
      "domain": [
        "geosite:category-ads-all"
      ],
      "outboundTag": "block"
    },
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "block"
      },    
    
    {
      "type": "field",
      "domain": [
        "geosite:cn"
      ],
      "outboundTag": "allow"
    }
  ]
},
  
  "outbounds": [
    {
      "protocol": "freedom",
      "tag":"allow"
    },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
  ]
}
EOF

cat << EOF > /Kaddyfile

http://localhost:443 {

   reverse_proxy $VL* http://127.0.0.1:2234  

    reverse_proxy * http://www.anneleephotography.com {    
        header_up Host {www.anneleephotography.com}    
        }

}

EOF


# Run xray caddy
/usr/local/bin/xray -config /usr/local/etc/xray/config.json  &

#caddy run 

caddy run --config /Kaddyfile --adapter caddyfile



