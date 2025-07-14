module yue;
import std::io;
import chunk;
import reader;
import state;

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

	return 0;
}
