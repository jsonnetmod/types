{
    foldlWithIndex(func, arr, init)::  (
      local aux(func, arr, running, idx) =
        if idx >= std.length(arr) then
          running
        else
          aux(func, arr, func(running, arr[idx], idx), idx + 1) tailstrict;
      aux(func, arr, init, 0)
    )
}