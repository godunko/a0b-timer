--
--  Copyright (C) 2024, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Internal API

pragma Restrictions (No_Elaboration_Code);

package A0B.Timer.Internals
  with Preelaborate
is

   procedure On_Tick with Inline_Always;

   procedure Initialize with Inline_Always;

end A0B.Timer.Internals;
