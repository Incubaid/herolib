module datamodel

// I can bid for infra, and optionally get accepted
@[heap]
pub struct Bid {
pub mut:
	id                u32
	customer_id       u32 // links back to customer for this capacity (user on ledger)
	compute_slices_nr int // nr of slices I need in 1 machine
	compute_slice     f64 // price per 1 GB slice I want to accept
	storage_slices    []u32
	status            BidStatus
	obligation        bool // if obligation then will be charged and money needs to be in escrow, otherwise its an intent
	start_date        u32  // epoch
	end_date          u32
}

pub enum BidStatus {
	pending
	confirmed
	assigned
	cancelled
	done
}
