module pet_store_actor

import freeflowuniverse.herolib.baobab.stage
import freeflowuniverse.herolib.core.redisclient
import x.json2 as json
import time

fn mock_response() ! {
	mut redis := redisclient.new('localhost:6379')!
	mut rpc_q := redis.rpc_get('actor_pet_store')
	for {
		rpc_q.process(fn (method string, data string) !string {
			return json.encode(method)
		})!
		time.sleep(time.millisecond * 100) // Prevent CPU spinning
	}
}

fn test_list_pets() ! {
	mut client := new_client()!
	limit := 10
	spawn mock_response()
	pets := client.list_pets(limit)!
	// assert pets.len <= limit
	println('test_list_pets passed')
}

fn test_create_pet() ! {
	mut client := new_client()!
	client.create_pet()!
	println('test_create_pet passed')
}

fn test_get_pet() ! {
	mut client := new_client()!
	pet_id := 1 // Replace with an actual pet ID in your system
	pet := client.get_pet(pet_id)!
	// assert pet.id == pet_id
	println('test_get_pet passed')
}

fn test_delete_pet() ! {
	mut client := new_client()!
	pet_id := 1 // Replace with an actual pet ID in your system
	client.delete_pet(pet_id)!
	println('test_delete_pet passed')
}

fn test_list_orders() ! {
	mut client := new_client()!
	client.list_orders()!
	println('test_list_orders passed')
}

fn test_get_order() ! {
	mut client := new_client()!
	order_id := 1 // Replace with an actual order ID in your system
	order := client.get_order(order_id)!
	// assert order.id == order_id
	println('test_get_order passed')
}

fn test_delete_order() ! {
	mut client := new_client()!
	order_id := 1 // Replace with an actual order ID in your system
	client.delete_order(order_id)!
	println('test_delete_order passed')
}

fn test_create_user() ! {
	mut client := new_client()!
	client.create_user()!
	println('test_create_user passed')
}
