structure buildcline_dtype =
struct

type t = {kernelspec : string option,
          debug : bool,
          help : bool,
          jobcount : int option,
          seqname : string option,
          build_theory_graph : bool option,
          selftest : int,
          relocbuild : bool}

val initial : t =
    { kernelspec = NONE, jobcount = NONE, seqname = NONE, help = false,
      build_theory_graph = NONE, selftest = 0, debug = false,
      relocbuild = false
    }

type 'a final_options =
     {build_theory_graph : bool,
      cmdline : string list,
      debug : bool,
      selftest_level : int,
      extra : 'a,
      jobcount : int,
      relocbuild : bool}




end
