module datamodelsimulator

import freeflowuniverse.herolib.threefold.grid4.datamodel { NodeCapacity }
import time

// NodeTotalSim represents the aggregated data for a node simulation, including hardware specs, pricing, and location.
pub struct NodeTotalSim {
pub mut:
	id               int          // Unique node ID
	cost             f64          // Total cost of the node
	deliverytime     time.Time    // Expected delivery time
	inca_reward      int          // Incentive reward
	reputation       int          // Reputation score (0-100)
	uptime           int          // Uptime percentage (0-100)
	price_simulation f64          // Simulated price for the node
	capacity         NodeCapacity // Aggregated hardware capacity
}

// // total aggregates totals for a single NodeSim (e.g., storage, memory, price) from its slices and devices.
// pub fn (n NodeTotalSim) total() !NodeTotalSim {
// 	if n.computeslices.len == 0 && n.storageslices.len == 0 {
// 		return error('Node has no slices to aggregate')
// 	}

// 	mut total := NodeTotalSim{
// 		id:               n.id
// 		cost:             n.cost
// 		deliverytime:     time.now() // Placeholder; replace with actual logic if needed
// 		inca_reward:      0  // Placeholder; compute from policy if available
// 		reputation:       50 // Default; compute from uptime/history
// 		uptime:           n.uptime
// 		price_simulation: 0.0
// 		capacity:         NodeCapacity{}
// 	}

// 	// Aggregate from compute slices
// 	for slice in n.computeslices {
// 		total.capacity.storage_gb += slice.storage_gb
// 		total.capacity.mem_gb += slice.mem_gb
// 		total.capacity.mem_gb_gpu += 0 // Add GPU logic if GPUs are in slices
// 		total.capacity.passmark += slice.passmark
// 		total.capacity.vcores += slice.vcores
// 		total.price_simulation += slice.price_cc
// 	}

// 	// Aggregate from storage slices (focus on storage/price)
// 	for slice in n.storageslices {
// 		total.capacity.storage_gb += 1.0 // Assuming 1GB per storage slice as per model_slices.v
// 		total.price_simulation += slice.price_cc
// 	}

// 	// Aggregate passmark/vcores from devices (e.g., CPUs)
// 	for cpu in n.devices.cpu {
// 		total.capacity.passmark += cpu.passmark
// 		total.capacity.vcores += cpu.cores
// 	}

// 	// Additional aggregations (e.g., from GPUs if present)
// 	for gpu in n.devices.gpu {
// 		total.capacity.mem_gb_gpu += gpu.memory_gb
// 		total.capacity.vcores += gpu.cores // If GPUs contribute to vcores
// 	}

// 	return total
// }
