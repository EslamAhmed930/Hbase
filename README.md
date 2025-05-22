# **HBase Cluster Architecture and Integration**  
**Documentation**  

---

## **1. Cluster Configuration**  

### **1.1 HBase Cluster Components**  
The HBase cluster is integrated with a highly available (HA) Hadoop cluster, ensuring fault tolerance and seamless operation.  

| **Component**          | **Nodes**                     | **Role** |
|------------------------|-------------------------------|----------|
| **HBase Master (HMaster)** | `hm1`, `hm2` (Active/Standby) | Manages metadata, region assignments, and failover |
| **RegionServers**       | `hr1`, `hr2`                  | Serve and manage data regions |
| **ZooKeeper Quorum**    | `master1`, `master2`, `master3` | Coordinates master election, failure detection |
| **Hadoop HA Cluster**   | `master1`, `master2`, `master3` | Provides HDFS storage and YARN resource management |

### **1.2 Integration with Hadoop HA**  
- **HDFS Storage**:  
  - Configured via `hbase.rootdir=hdfs://mycluster:8020/hbase`  
  - Uses Hadoop’s HA NameNodes (`nn1`, `nn2`, `nn3`)  
  - Replication factor: `1` (adjustable via `dfs.replication`)  

- **ZooKeeper Coordination**:  
  - Shared with Hadoop HA (`hbase.zookeeper.quorum=master1,master2,master3`)  
  - Ensures master election and failure detection  

- **Network Setup**:  
  - All containers on `hadoopnetwork` (Docker bridge)  
  - Internal DNS resolution via hostnames (`master1`, `hr1`, etc.)  
  - Port mappings for external access (e.g., HMaster UI on `16010`)  

---

## **2. High Availability & Failover**  

### **2.1 Master Node Failover**  
- **Automatic Failover via ZooKeeper**:  
  - Active HMaster registers itself in ZooKeeper.  
  - Standby monitors ZooKeeper for leadership changes.  
  - **Failover Time**: Typically **30-60 seconds**.  

- **Key Configurations (`hbase-site.xml`)**:
  ```xml
  <property>
    <name>hbase.master.wait.on.regionservers.mintostart</name>
    <value>1</value> <!-- Minimum RegionServers needed -->
  </property>
  <property>
    <name>hbase.master.wait.on.regionservers.timeout</name>
    <value>60000</value> <!-- 60s timeout -->
  </property>
  ```

- **Failover Process**:  
  1. Active HMaster fails (crash/network issue).  
  2. ZooKeeper detects session expiration (~90s).  
  3. Standby HMaster acquires lock in ZooKeeper.  
  4. New HMaster loads metadata and takes over.  

### **2.2 RegionServer Failover**  
- **Automatic Recovery**:  
  - HMaster detects failure via ZooKeeper.  
  - Failed regions reassigned to healthy RegionServers.  
  - **WAL (Write-Ahead Log) replay** ensures data consistency.  

- **Key Configurations**:
  ```xml
  <property>
    <name>hbase.regionserver.restart.on.throwable</name>
    <value>false</value> <!-- Set to true for auto-restart -->
  </property>
  <property>
    <name>hbase.regionserver.handler.count</name>
    <value>30</value> <!-- Threads for handling requests -->
  </property>
  ```

- **Failover Process**:  
  1. RegionServer fails (process crash).  
  2. HMaster marks regions as offline.  
  3. Regions reassigned to other servers.  
  4. WAL replay recovers uncommitted data.  

---

## **3. Testing & Validation**  

### **3.1 Test Scenarios**  

| **Test Case**                | **Procedure** | **Expected Result** |
|------------------------------|--------------|---------------------|
| **HMaster Process Kill**     | `kill -9 <pid>` | Standby takes over in ≤60s |
| **Network Partition**        | Block traffic to active HMaster | Standby promotes, clients reconnect |
| **ZooKeeper Leader Failure** | Stop ZooKeeper leader | Cluster remains operational |
| **RegionServer Crash**       | Kill a RegionServer | Regions reassigned, no data loss |

### **3.2 Recovery Metrics**  
- **Time to failover** (HMaster & RegionServer).  
- **WAL replay duration**.  
- **Client operation impact** (latency during failover).  

### **3.3 Verification Steps**  
1. **Data Integrity Check**:  
   - Run `hbase hbck` to verify consistency.  
   - Compare pre/post-failure row counts.  
2. **Client Resilience**:  
   - Ensure clients reconnect automatically.  
   - Verify no duplicate/missing data.  

---

## **4. Implementation Notes**  

### **4.1 Critical Configurations**  
- **`hbase-site.xml`**: Defines HA, ZooKeeper, and HDFS settings.  
- **`zoo.cfg`**: Shared ZooKeeper quorum for HBase & Hadoop.  
- **`core-site.xml`**: Ensures HDFS HA access (`hdfs://mycluster`).  

### **4.2 Startup Sequence**  
1. **Hadoop HA cluster** must be healthy first.  
2. **HMaster nodes** start after HDFS is ready.  
3. **RegionServers** launch once masters are active.  

### **4.3 Security Considerations**  
- All services run as `hadoop` user.  
- HDFS permissions set for `/hbase`.  
- **Kerberos** can be added for production security.  

---

### **Conclusion**  
This architecture provides a **highly available HBase cluster** with:  
✔ **Automatic failover** for HMaster and RegionServers.  
✔ **Seamless Hadoop HA integration**.  
✔ **Resilient testing & recovery procedures**.  

**Next Steps**:  
- Simulate failures to measure recovery times.  
- Adjust replication factor (`dfs.replication`) if needed.  
- Consider Kerberos for enterprise security.  

---




