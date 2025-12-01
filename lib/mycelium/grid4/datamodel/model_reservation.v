module datamodel

@[heap]
pub struct Reservation {
pub mut:
	id             u32
	customer_id    u32 // links back to customer for this capacity
	compute_slices []u32
	storage_slices []u32
	status         ReservationStatus
	start_date     u32 // epoch
	end_date       u32
}

pub enum ReservationStatus {
	pending
	confirmed
	assigned
	cancelled
	done
}
