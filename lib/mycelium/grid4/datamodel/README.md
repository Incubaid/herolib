
# Grid4 Data Model

This module defines data models for nodes, groups, and slices in a cloud/grid infrastructure. Each root object is marked with `@[heap]` and can be indexed for efficient querying.

## Root Objects Overview

| Object      | Description                                   | Index Fields                   |
| ----------- | --------------------------------------------- | ------------------------------ |
| `Node`      | Represents a single node in the grid          | `id`, `nodegroupid`, `country` |
| `NodeGroup` | Represents a group of nodes owned by a farmer | `id`, `farmerid`               |

---

## Node

Represents a single node in the grid with slices, devices, and capacity.

| Field           | Type             | Description                                  | Indexed |
| --------------- | ---------------- | -------------------------------------------- | ------- |
| `id`            | `int`            | Unique node ID                               | ✅       |
| `nodegroupid`   | `int`            | ID of the owning node group                  | ✅       |
| `uptime`        | `int`            | Uptime percentage (0-100)                    | ✅       |
| `computeslices` | `[]ComputeSlice` | List of compute slices                       | ❌       |
| `storageslices` | `[]StorageSlice` | List of storage slices                       | ❌       |
| `devices`       | `DeviceInfo`     | Hardware device info (storage, memory, etc.) | ❌       |
| `country`       | `string`         | 2-letter country code                        | ✅       |
| `capacity`      | `NodeCapacity`   | Aggregated hardware capacity                 | ❌       |
| `provisiontime` | `u32`            | Provisioning time (simple/compatible format) | ✅       |

---

## NodeGroup

Represents a group of nodes owned by a farmer, with policies.

| Field                                 | Type            | Description                                    | Indexed |
| ------------------------------------- | --------------- | ---------------------------------------------- | ------- |
| `id`                                  | `u32`           | Unique group ID                                | ✅       |
| `farmerid`                            | `u32`           | Farmer/user ID                                 | ✅       |
| `secret`                              | `string`        | Encrypted secret for booting nodes             | ❌       |
| `description`                         | `string`        | Group description                              | ❌       |
| `slapolicy`                           | `SLAPolicy`     | SLA policy details                             | ❌       |
| `pricingpolicy`                       | `PricingPolicy` | Pricing policy details                         | ❌       |
| `compute_slice_normalized_pricing_cc` | `f64`           | Pricing per 2GB compute slice in cloud credits | ❌       |
| `storage_slice_normalized_pricing_cc` | `f64`           | Pricing per 1GB storage slice in cloud credits | ❌       |
| `reputation`                          | `int`           | Reputation (0-100)                             | ✅       |
| `uptime`                              | `int`           | Uptime (0-100)                                 | ✅       |

---

## ComputeSlice

Represents a compute slice (e.g., 1GB memory unit).

| Field                      | Type            | Description                      |
| -------------------------- | --------------- | -------------------------------- |
| `nodeid`                   | `u32`           | Owning node ID                   |
| `id`                       | `int`           | Slice ID in node                 |
| `mem_gb`                   | `f64`           | Memory in GB                     |
| `storage_gb`               | `f64`           | Storage in GB                    |
| `passmark`                 | `int`           | Passmark score                   |
| `vcores`                   | `int`           | Virtual cores                    |
| `cpu_oversubscription`     | `int`           | CPU oversubscription ratio       |
| `storage_oversubscription` | `int`           | Storage oversubscription ratio   |
| `price_range`              | `[]f64`         | Price range [min, max]           |
| `gpus`                     | `u8`            | Number of GPUs                   |
| `price_cc`                 | `f64`           | Price per slice in cloud credits |
| `pricing_policy`           | `PricingPolicy` | Pricing policy                   |
| `sla_policy`               | `SLAPolicy`     | SLA policy                       |

---

## StorageSlice

Represents a 1GB storage slice.

| Field            | Type            | Description                      |
| ---------------- | --------------- | -------------------------------- |
| `nodeid`         | `u32`           | Owning node ID                   |
| `id`             | `int`           | Slice ID in node                 |
| `price_cc`       | `f64`           | Price per slice in cloud credits |
| `pricing_policy` | `PricingPolicy` | Pricing policy                   |
| `sla_policy`     | `SLAPolicy`     | SLA policy                       |

---

## DeviceInfo

Hardware device information for a node.

| Field     | Type              | Description             |
| --------- | ----------------- | ----------------------- |
| `vendor`  | `string`          | Vendor of the node      |
| `storage` | `[]StorageDevice` | List of storage devices |
| `memory`  | `[]MemoryDevice`  | List of memory devices  |
| `cpu`     | `[]CPUDevice`     | List of CPU devices     |
| `gpu`     | `[]GPUDevice`     | List of GPU devices     |
| `network` | `[]NetworkDevice` | List of network devices |

---

## StorageDevice

| Field         | Type     | Description           |
| ------------- | -------- | --------------------- |
| `id`          | `string` | Unique ID for device  |
| `size_gb`     | `f64`    | Size in GB            |
| `description` | `string` | Description of device |

---

## MemoryDevice

| Field         | Type     | Description           |
| ------------- | -------- | --------------------- |
| `id`          | `string` | Unique ID for device  |
| `size_gb`     | `f64`    | Size in GB            |
| `description` | `string` | Description of device |

---

## CPUDevice

| Field         | Type     | Description              |
| ------------- | -------- | ------------------------ |
| `id`          | `string` | Unique ID for device     |
| `cores`       | `int`    | Number of CPU cores      |
| `passmark`    | `int`    | Passmark benchmark score |
| `description` | `string` | Description of device    |
| `cpu_brand`   | `string` | Brand of the CPU         |
| `cpu_version` | `string` | Version of the CPU       |

---

## GPUDevice

| Field         | Type     | Description           |
| ------------- | -------- | --------------------- |
| `id`          | `string` | Unique ID for device  |
| `cores`       | `int`    | Number of GPU cores   |
| `memory_gb`   | `f64`    | GPU memory in GB      |
| `description` | `string` | Description of device |
| `gpu_brand`   | `string` | Brand of the GPU      |
| `gpu_version` | `string` | Version of the GPU    |

---

## NetworkDevice

| Field         | Type     | Description           |
| ------------- | -------- | --------------------- |
| `id`          | `string` | Unique ID for device  |
| `speed_mbps`  | `int`    | Network speed in Mbps |
| `description` | `string` | Description of device |

---

## NodeCapacity

Aggregated hardware capacity for a node.

| Field        | Type  | Description            |
| ------------ | ----- | ---------------------- |
| `storage_gb` | `f64` | Total storage in GB    |
| `mem_gb`     | `f64` | Total memory in GB     |
| `mem_gb_gpu` | `f64` | Total GPU memory in GB |
| `passmark`   | `int` | Total passmark score   |
| `vcores`     | `int` | Total virtual cores    |

---

## SLAPolicy

Service Level Agreement policy for slices or node groups.

| Field                | Type  | Description                             |
| -------------------- | ----- | --------------------------------------- |
| `sla_uptime`         | `int` | Required uptime % (e.g., 90)            |
| `sla_bandwidth_mbit` | `int` | Guaranteed bandwidth in Mbps (0 = none) |
| `sla_penalty`        | `int` | Penalty % if SLA is breached (0-100)    |

---

## PricingPolicy

Pricing policy for slices or node groups.

| Field                        | Type    | Description                                               |
| ---------------------------- | ------- | --------------------------------------------------------- |
| `marketplace_year_discounts` | `[]int` | Discounts for 1Y, 2Y, 3Y prepaid usage (e.g. [30,40,50])  |
| `volume_discounts`           | `[]int` | Volume discounts based on purchase size (e.g. [10,20,30]) |


