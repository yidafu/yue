module yue;

import std::io;
import chunk;
import reader;
import state;
import vm;

fn int main(String[] args)
{
	String luac_file = args[1];
	char[]? content = file::load_temp(luac_file);
	if (catch err = content)
	{
		io::printfn("Error: unable to read file %s", luac_file);
		return 1;
	}

	Reader reader = { content };

	BinaryChunk chunk = reader.undump();
	chunk.mainFunc.print();
	
	lua_main(chunk.mainFunc);
	return 0;
}

fn void lua_main(Prototype proto) {
	usz regs = (usz)proto.max_stack_size;
	LuaVm vm = vm::new_vm(regs + 8, proto);
	vm.set_top((int)regs);
	while(true) {
		uint pc = vm.pc;
		Instruction i = vm.patch();
		OpCode opCode = i.op_code();
		if (opCode != OpCode.OP_RETURN) {
			vm.execute(i);
			io::printf("[%02d] %s", pc+1, opCode.desc);
			vm.print_stack();
		} else {
			break;
		}
	}
}