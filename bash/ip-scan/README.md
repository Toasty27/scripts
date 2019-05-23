# Usage

```
ip-scan.sh <subnet> <start> <end>

subnet: The first three octets of the address range to be scanned
start:  Start of range, [1-255]
end:    End of range, [1-255] (must be larger than start value)
```

### example

Scans the first 20 addresses of the `192.168.1.0/24` subnet:

```
ip-scan.sh 192.168.1 1 20
```

Scans a full `10.0.0.0/16` subnet:

```
for i in $(seq 0 255); do
	./ip-scan.sh 10.0.${i} 0 255
done
```
