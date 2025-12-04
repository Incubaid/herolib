module namecomclient

import incubaid.herolib.core.base
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console
import json

__global (
	namecomclient_global  map[string]&NamecomClient
	namecomclient_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name   string = 'default'
	fromdb bool // will load from filesystem
	create bool // default will not create if not exist
}

pub fn new(args ArgsGet) !&NamecomClient {
	mut obj := NamecomClient{
		name: args.name
	}
	set(obj)!
	return get(name: args.name)!
}

pub fn get(args ArgsGet) !&NamecomClient {
	mut context := base.context()!
	namecomclient_default = args.name
	if args.fromdb || args.name !in namecomclient_global {
		mut r := context.redis()!
		if r.hexists('context:namecomclient', args.name)! {
			data := r.hget('context:namecomclient', args.name)!
			if data.len == 0 {
				print_backtrace()
				return error('NamecomClient with name: ${args.name} does not exist, prob bug.')
			}
			mut obj := json.decode(NamecomClient, data)!
			set_in_mem(obj)!
		} else {
			if args.create {
				new(args)!
			} else {
				print_backtrace()
				return error("NamecomClient with name '${args.name}' does not exist")
			}
		}
		return get(name: args.name)! // no longer from db nor create
	}
	return namecomclient_global[args.name] or {
		print_backtrace()
		return error('could not get config for namecomclient with name:${args.name}')
	}
}

// register the config for the future
pub fn set(o NamecomClient) ! {
	mut o2 := set_in_mem(o)!
	namecomclient_default = o2.name
	mut context := base.context()!
	mut r := context.redis()!
	r.hset('context:namecomclient', o2.name, json.encode(o2))!
}

// does the config exists?
pub fn exists(args ArgsGet) !bool {
	mut context := base.context()!
	mut r := context.redis()!
	return r.hexists('context:namecomclient', args.name)!
}

pub fn delete(args ArgsGet) ! {
	mut context := base.context()!
	mut r := context.redis()!
	r.hdel('context:namecomclient', args.name)!
}

@[params]
pub struct ArgsList {
pub mut:
	fromdb bool // will load from filesystem
}

// if fromdb set: load from filesystem, and not from mem, will also reset what is in mem
pub fn list(args ArgsList) ![]&NamecomClient {
	mut res := []&NamecomClient{}
	mut context := base.context()!
	if args.fromdb {
		// reset what is in mem
		namecomclient_global = map[string]&NamecomClient{}
		namecomclient_default = ''
	}
	if args.fromdb {
		mut r := context.redis()!
		mut l := r.hkeys('context:namecomclient')!

		for name in l {
			res << get(name: name, fromdb: true)!
		}
		return res
	} else {
		// load from memory
		for _, client in namecomclient_global {
			res << client
		}
	}
	return res
}

// only sets in mem, does not set as config
fn set_in_mem(o NamecomClient) !NamecomClient {
	mut o2 := obj_init(o)!
	namecomclient_global[o2.name] = &o2
	namecomclient_default = o2.name
	return o2
}

pub fn play(mut plbook PlayBook) ! {
	if !plbook.exists(filter: 'namecomclient.') {
		return
	}
	// Handle configure actions
	mut install_actions := plbook.find(filter: 'namecomclient.configure')!
	if install_actions.len > 0 {
		for mut install_action in install_actions {
			heroscript := install_action.heroscript()
			mut obj2 := heroscript_loads(heroscript)!
			set(obj2)!
			install_action.done = true
		}
	}

	// Handle other actions
	mut other_actions := plbook.find(filter: 'namecomclient.')!
	for mut action in other_actions {
		if action.done {
			continue
		}
		mut p := action.params
		name := p.get_default('name', 'default')!
		mut client := get(name: name)!

		match action.name {
			'domains_list' {
				console.print_debug('action namecomclient.domains_list')
				domains := client.list_domains()!
				for domain in domains {
					console.print_stdout('${domain.domain_name} (expires: ${domain.expire_date})')
				}
			}
			'records_list' {
				console.print_debug('action namecomclient.records_list')
				domain := p.get('domain')!
				records := client.list_records(domain)!
				for record in records {
					console.print_stdout('${record.host}.${record.domain_name} ${record.record_type} ${record.answer} (TTL: ${record.ttl})')
				}
			}
			'record_set' {
				console.print_debug('action namecomclient.record_set')
				domain := p.get('domain')!
				host := p.get_default('host', '')!
				record_type := p.get_default('type', 'A')!
				answer := p.get('answer')!
				ttl := p.get_u32_default('ttl', 300)!
				priority := p.get_u32_default('priority', 0)!

				// Check if record exists, update or create
				existing_records := client.list_records(domain)!
				mut found := false
				for record in existing_records {
					if record.host == host && record.record_type == record_type {
						// Update existing record
						client.update_record(domain, record.id, UpdateRecordRequest{
							host:        host
							record_type: record_type
							answer:      answer
							ttl:         ttl
							priority:    priority
						})!
						console.print_stdout('Updated ${record_type} record for ${host}.${domain} -> ${answer}')
						found = true
						break
					}
				}
				if !found {
					// Create new record
					client.create_record(domain, CreateRecordRequest{
						host:        host
						record_type: record_type
						answer:      answer
						ttl:         ttl
						priority:    priority
					})!
					console.print_stdout('Created ${record_type} record for ${host}.${domain} -> ${answer}')
				}
			}
			'record_delete' {
				console.print_debug('action namecomclient.record_delete')
				domain := p.get('domain')!
				host := p.get_default('host', '')!
				record_type := p.get_default('type', 'A')!

				existing_records := client.list_records(domain)!
				for record in existing_records {
					if record.host == host && record.record_type == record_type {
						client.delete_record(domain, record.id)!
						console.print_stdout('Deleted ${record_type} record for ${host}.${domain}')
						break
					}
				}
			}
			'check_availability' {
				console.print_debug('action namecomclient.check_availability')
				domains_str := p.get('domains')!
				domain_list := domains_str.split(',').map(it.trim_space())
				results := client.check_availability(domain_list)!
				for result in results {
					status := if result.purchasable { 'available' } else { 'taken' }
					console.print_stdout('${result.domain_name}: ${status}')
				}
			}
			else {}
		}
		action.done = true
	}
}

// switch instance to be used for namecomclient
pub fn switch(name string) {
	namecomclient_default = name
}
