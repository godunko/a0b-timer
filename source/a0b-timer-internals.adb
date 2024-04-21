--
--  Copyright (C) 2024, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package body A0B.Timer.Internals is

   procedure Initialize renames A0B.Timer.Internal_Initialize;

   procedure On_Tick renames A0B.Timer.Internal_On_Tick;

end A0B.Timer.Internals;