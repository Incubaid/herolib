module heromodels

import freeflowuniverse.herolib.schemas.openrpc



// // Re-export core methods from openrpcserver for convenience
// pub fn set[T](mut obj T) !u32 {
// 	return openrpcserver.set[T](mut obj)!
// }

// pub fn get[T](id u32) !T {
// 	return openrpcserver.get[T](id)!
// }

// pub fn exists[T](id u32) !bool {
// 	return openrpcserver.exists[T](id)!
// }

// pub fn delete[T](id u32) ! {
// 	openrpcserver.delete[T](id)!
// }

// pub fn list[T]() ![]T {
// 	return openrpcserver.list[T]()!
// }

// // Re-export utility functions
// pub fn tags2id(tags []string) !u32 {
// 	return openrpcserver.tags2id(tags)!
// }

// pub fn comment_multiset(args []CommentArg) ![]u32 {
// 	return openrpcserver.comment_multiset(args)!
// }

// pub fn comments2ids(args []CommentArg) ![]u32 {
// 	return openrpcserver.comments2ids(args)!
// }

// pub fn comment2id(comment string) !u32 {
// 	return openrpcserver.comment2id(comment)!
// }

// pub fn new_base(args BaseArgs) !Base {
// 	return openrpcserver.new_base(args)!
// }
