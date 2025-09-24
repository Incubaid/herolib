### 1. **Network namespaces**

* Each namespace can have its own interfaces, routing table, firewall rules, etc.
* You can move the user’s processes into a network namespace that only has access to a given bridge.

Example:

```bash
# Create a new netns for user "alice"
ip netns add alice

# Add a veth pair
ip link add veth-alice type veth peer name veth-alice-br

# Attach one side to the bridge
ip link set veth-alice-br master br0
ip link set veth-alice-br up

# Move the other side into the netns
ip link set veth-alice netns alice

# Configure inside namespace
ip netns exec alice ip addr add 192.168.100.2/24 dev veth-alice
ip netns exec alice ip link set veth-alice up
ip netns exec alice ip route add default via 192.168.100.1

# Now run a shell in alice’s namespace
sudo -u alice ip netns exec alice bash
```

Now all processes run by `alice` will use only that veth → bridge → network.


