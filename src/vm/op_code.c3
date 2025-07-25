module vm;
enum OpArgMode : char (String desc) {
  OP_ARG_N = "OpArgN",
  OP_ARG_U = "OpArgU",
  OP_ARG_R = "OpArgR",
  OP_ARG_K = "OpArgK",
}
enum OpMode : char (String desc) {
  IABC = "IABC",
  IA_BX = "IABx",
  IA_SBX = "IAsBx",
  I_AX = "IAx",
}

enum OpCode : char (
	String desc, 
	OpMode mode, 
	bool set_a_flag, 
	OpArgMode arg_b_mode, 
	OpArgMode arg_c_mode, 
	bool test_flag,
) {
  // R(A) := R(B)
  OP_MOVE = { "MOVE", OpMode.IABC, true, OpArgMode.OP_ARG_R, OpArgMode.OP_ARG_N, false, },
  // R(A) := Kst(Bx)
	OP_LOADK = { "LOADK", OpMode.IA_BX, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_N, false},
  // R(A) := Kst(extra arg)
	OP_LOADKX = { "LOADKX", OpMode.IA_BX, true, OpArgMode.OP_ARG_N, OpArgMode.OP_ARG_N, false},
  // R(A) := (bool)B; if (C) pc++
	OP_LOADBOOL = { "LOADBOOL", OpMode.IABC, true, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_U, false},
// R(A), R(A+1), ..., R(A+B) := nil
	OP_LOADNIL = { "LOADNIL", OpMode.IABC, true, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_N, false},
// R(A) := UpValue[B]
	OP_GETUPVAL = { "GETUPVAL", OpMode.IABC, true, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_N, false},
// R(A) := UpValue[B][RK(C)]
	OP_GETTABUP = { "GETTABUP", OpMode.IABC, true, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_K, false},
// R(A) := R(B)[RK(C)]
	OP_GETTABLE = { "GETTABLE", OpMode.IABC, true, OpArgMode.OP_ARG_R, OpArgMode.OP_ARG_K, false},
 // UpValue[A][RK(B)] := RK(C)
	OP_SETTABUP = { "SETTABUP", OpMode.IABC, false, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
// UpValue[B] := R(A)
	OP_SETUPVAL = { "SETUPVAL", OpMode.IABC, false, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_N, false},
 // R(A)[RK(B)] := RK(C)
	OP_SETTABLE = { "SETTABLE", OpMode.IABC, false, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
// R(A) := {} (size = B,C)
	OP_NEWTABLE = { "NEWTABLE", OpMode.IABC, true, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_U, false},
 // R(A+1) := R(B); R(A) := R(B)[RK(C)]
	OP_SELF = { "SELF", OpMode.IABC, true, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_U, false},
// R(A) := RK(B) + RK(C)
	OP_ADD = { "ADD", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
 // R(A) := RK(B) - RK(C)
	OP_SUB = { "SUB", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
 // R(A) := RK(B) * RK(C)
	OP_MUL = { "MUL", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
 // R(A) := RK(B) % RK(C)
	OP_MOD = { "MOD", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
// R(A) := RK(B) ^ RK(C)
	OP_POW = { "POW", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
// R(A) := RK(B) / RK(C)
	OP_DIV = { "DIV", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
// R(A) := RK(B) // RK(C)
	OP_IDIV = { "IDIV", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
// R(A) := RK(B) & RK(C)
	OP_BAND = { "BAND", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
// R(A) := RK(B) | RK(C)
	OP_BOR = { "BOR", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
// R(A) := RK(B) ~ RK(C)
	OP_BXOR = { "BXOR", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
  // R(A) := RK(B) << RK(C)
	OP_SHL = { "SHL", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
  // R(A) := RK(B) >> RK(C)
	OP_SHR = { "SHR", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, false},
   // R(A) := -R(B)
	OP_UNM = { "UNM", OpMode.IABC, true, OpArgMode.OP_ARG_R, OpArgMode.OP_ARG_N, false},
// R(A) := ~R(B)
	OP_BNOT = { "BNOT", OpMode.IABC, true, OpArgMode.OP_ARG_R, OpArgMode.OP_ARG_N, false},
 // R(A) := not R(B)
	OP_NOT = { "NOT", OpMode.IABC, true, OpArgMode.OP_ARG_R, OpArgMode.OP_ARG_N, false},
// R(A) := length of R(B)
	OP_LEN = { "LEN", OpMode.IABC, true, OpArgMode.OP_ARG_R, OpArgMode.OP_ARG_N, false},
  // R(A) := R(B).. ... ..R(C)
	OP_CONCAT = { "CONCAT", OpMode.IABC, true, OpArgMode.OP_ARG_R, OpArgMode.OP_ARG_N, false},
// pc+=sBx; if (A) close all upvalues >= R(A - 1)
	OP_JMP = { "JMP", OpMode.IA_SBX, false, OpArgMode.OP_ARG_R, OpArgMode.OP_ARG_N, false},
// if ((RK(B) == RK(C)) ~= A) then pc++
	OP_EQ = { "EQ", OpMode.IABC, false, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, true},
  // if ((RK(B) <  RK(C)) ~= A) then pc++
	OP_LT = { "LT", OpMode.IABC, false, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, true},
  // if ((RK(B) <= RK(C)) ~= A) then pc++
	OP_LE = { "LE", OpMode.IABC, false, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_K, true},
  // if not (R(A) <=> C) then pc++
	OP_TEST = { "TEST", OpMode.IABC, false, OpArgMode.OP_ARG_N, OpArgMode.OP_ARG_U, true},
// if (R(B) <=> C) then R(A) := R(B) else pc++
	OP_TESTSET = { "TESTSET", OpMode.IABC, true, OpArgMode.OP_ARG_R, OpArgMode.OP_ARG_U, true},
  // / R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
	OP_CALL = { "CALL", OpMode.IABC, true, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_U, false},
// return R(A)(R(A+1), ... ,R(A+B-1))
	OP_TAILCALL = { "TAILCALL", OpMode.IABC, true, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_U, false},
// return R(A), ... ,R(A+B-2)
	OP_RETURN = { "RETURN", OpMode.IABC, false, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_N, false},
// R(A)+=R(A+2); if R(A) <?= R(A+1) then { pc+=sBx; R(A+3)=R(A) }
	OP_FORLOOP = { "FORLOOP", OpMode.IA_SBX, true, OpArgMode.OP_ARG_R, OpArgMode.OP_ARG_N, false},
 // R(A)-=R(A+2); pc+=sBx
	OP_FORPREP = { "FORPREP", OpMode.IA_SBX, false, OpArgMode.OP_ARG_R, OpArgMode.OP_ARG_N, false},
// R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
	OP_TFORCALL = { "TFORCALL", OpMode.IABC, false, OpArgMode.OP_ARG_N, OpArgMode.OP_ARG_U, false},
  // if R(A+1) ~= nil then { R(A)=R(A+1); pc += sBx }
	OP_TFORLOOP = { "TFORLOOP", OpMode.IABC, true, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_N, false},
// R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
	OP_SETLIST = { "SETLIST", OpMode.IABC, false, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_U, false},
// R(A) := closure(KPROTO[Bx])
	OP_CLOSURE = { "CLOSURE", OpMode.IABC, true, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_N, false},
// R(A), R(A+1), ..., R(A+B-2) = vararg
	OP_VARARG = { "VARARG", OpMode.IABC, true, OpArgMode.OP_ARG_U, OpArgMode.OP_ARG_N, false},
// extra (larger) argument for previous opcode
	OP_EXTRAARG = { "EXTRAARG", OpMode.I_AX, false, OpArgMode.OP_ARG_K, OpArgMode.OP_ARG_N, false},
}

