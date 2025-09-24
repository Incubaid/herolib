# Grid4 Data Model

This module defines data models for nodes, groups, slices, and simulations in a cloud/grid infrastructure.

## Node

Represents a single node in the grid with slices, devices, and capacity.

| Field          | Type              | Description |
|----------------|-------------------|-------------|
| id             | int               | Unique node ID |
| nodegroupid    | int               | ID of the owning node group |
| uptime         | int               | Uptime percentage (0-100) |
| computeslices  | []ComputeSlice    | List of compute slices |
| storageslices  | []StorageSlice    | List of storage slices |
| devices        | DeviceInfo        | Hardware device info (storage, memory, etc.) |
| country        | string            | 2-letter country code |
| capacity       | NodeCapacity      | Aggregated hardware capacity |
| provisiontime  | u32               | Provisioning time (simple/compatible format) |

## NodeGroup

Represents a group of nodes owned by a farmer, with policies.

| Field                  | Type          | Description |
|------------------------|---------------|-------------|
| id                     | u32           | Unique group ID |
| farmerid               | u32           | Farmer/user ID |
| secret                 | string        | Encrypted secret for booting nodes |
| description            | string        | Group description |
| slapolicy              | SLAPolicy     | SLA policy details |
| pricingpolicy          | PricingPolicy | Pricing policy details |
| compute_slice_normalized_pricing_cc | f64 | Pricing per 2GB compute slice in cloud credits |
| storage_slice_normalized_pricing_cc | f64 | Pricing per 1GB storage slice in cloud credits |
| reputation             | int           | Reputation (0-100) |
| uptime                 | int           | Uptime (0-100) |

## NodeSim

Extends Node for simulation purposes with cost.

| Field | Type | Description |
|-------|------|-------------|
| ( Embeds Node ) | - | All Node fields |
| cost  | f64  | Simulation cost (free in some contexts) |

## ComputeSlice

Represents a compute slice (e.g., 1GB memory unit).

| Field                       | Type          | Description |
|-----------------------------|---------------|-------------|
| nodeid                      | u32           | Owning node ID |
| id                          | int           | Slice ID in node |
| mem_gb                      | f64           | Memory in GB |
| storage_gb                  | f64           | Storage in GB |
| passmark                    | int           | Passmark score |
| vcores                      | int           | Virtual cores |
| cpu_oversubscription        | int           | CPU oversubscription ratio |
| storage_oversubscription    | int           | Storage oversubscription ratio |
| price_range                 | []f64         | Price range [min, max] |
| gpus                        | u8            | Number of GPUs |
| price_cc                    | f64           | Price per slice in cloud credits |
| pricing_policy              | PricingPolicy | Pricing policy |
| sla_policy                  | SLAPolicy     | SLA policy |

## StorageSlice

Represents a 1GB storage slice.

| Field            | Type          | Description |
|------------------|---------------|-------------|
| nodeid           | u32           | Owning node ID |
| id               | int           | Slice ID in node |
| price_cc         | f64           | Price per slice in cloud credits |
| pricing_policy   | PricingPolicy | Pricing policy |
| sla_policy       | SLAPolicy     | SLA policy |

## NodeCapacity

Aggregated hardware capacity for a node.

| Field        | Type | Description |
|--------------|------|-------------|
| storage_gb   | f64  | Total storage in GB |
| mem_gb       | f64  | Total memory in GB |
| mem_gb_gpu   | f64  | Total GPU memory in GB |
| passmark     | int  | Total passmark score |
| vcores       | int  | Total virtual cores |

## NodeTotalSim

Aggregated simulation data for a node.

| Field              | Type        | Description |
|--------------------|-------------|-------------|
| id                 | int         | Unique node ID |
| cost               | f64         | Total cost |
| deliverytime       | time.Time   | Delivery time |
| inca_reward        | int         | Incentive reward |
| reputation         | int         | Reputation (0-100) |
| uptime             | int         | Uptime (0-100) |
| price_simulation   | f64         | Simulated price |
| info               | NodeInfo    | Descriptive info |
| capacity           | NodeCapacity| Aggregated capacity |

## NodeInfo

Descriptive info for a node (used in aggregations).

| Field        | Type   | Description |
|--------------|--------|-------------|
| cpu_brand    | string | CPU brand |
| cpu_version  | string | CPU version |
| mem          | string | Memory description |
| hdd          | string | HDD description |
| ssd          | string | SSD description |
| url          | string | Info URL |
| continent    | string | Continent code |
| country      | string | Country code |
