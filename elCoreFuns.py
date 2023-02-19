



names = [
    "meter", "scope", "fft", "snapshot", "accum", "const",
    "counter", "db2gain", "maxhold", "metro", "ms2samps", "select", "sr",
    "tau2pole", "time", "delay", "sdelay", "tapIn", "tapOut", "z", "compress",
    "allpass", "bandpass", "biquad", "convolve", "dcblock", "df11", "highpass",
    "highshelf", "lowpass", "lowshelf", "notch", "peak", "pink", "pole", "scope",
    "sm", "smooth", "zero", "rand", "noise", "pinknoise", "blepsaw", "blepsquare",
    "bleptriangle", "cycle", "phasor", "saw", "square", "train", "triangle",
    "sample", "table", "adsr", "env", "latch", "select", "seq", "seq2", "sparseq",
    "in", "sin", "cos", "tan", "tanh", "asinh", "ln", "log", "log2", "ceil",
    "floor", "sqrt", "exp", "abs", "eq", "and", "or", "le", "leq", "ge", "geq",
    "pow", "mod", "min", "max", "add", "sub", "mul", "div",
]



if __name__ == "__main__":
    longest = max(map(len, names))
    for name in names:
        pad = "".join([" " for _ in range(longest - len(name))])
        print(f"export const {name} {pad}= (...props) => el.{name}(...props)")
    print(longest)
