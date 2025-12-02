module core
import incubaid.herolib.core.texttools

// pub fn init()!KubeClient {



// 	//TODO: get installer kubectl, and check if installed if not do
// }


pub fn name_fix(s string) string {
	return texttools.name_fix(s).replace('_', '')
}