module user

@[heap]
pub struct UserRef {
pub mut:
	id         u32
	public_key string
	name       string
	email      string
	roles      []string
}
