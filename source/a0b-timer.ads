--
--  Copyright (C) 2024, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  pragma Restrictions (No_Elaboration_Code);

with A0B.Callbacks;
with A0B.Time;

package A0B.Timer
  with Preelaborate
is

   type Timeout_Control_Block is limited private
     with Preelaborable_Initialization;

   procedure Enqueue
     (Event    : aliased in out Timeout_Control_Block;
      Callback : A0B.Callbacks.Callback;
      T        : A0B.Time.Duration);

   procedure Enqueue
     (Event    : aliased in out Timeout_Control_Block;
      Callback : A0B.Callbacks.Callback;
      T        : A0B.Time.Time_Span);

   procedure Enqueue
     (Event    : aliased in out Timeout_Control_Block;
      Callback : A0B.Callbacks.Callback;
      T        : A0B.Time.Monotonic_Time);

   procedure Cancel (Event : aliased in out Timeout_Control_Block);

   function Is_Set (Event : Timeout_Control_Block) return Boolean;

private

   type Timeout_Control_Block_Access is access all Timeout_Control_Block;

   type Timeout_Control_Block is limited record
      Time_Stamp : A0B.Time.Monotonic_Time;
      Callback   : A0B.Callbacks.Callback;
      Next       : Timeout_Control_Block_Access;
   end record;

   procedure Internal_Initialize;

   procedure Internal_On_Tick;

   function Is_Set (Event : Timeout_Control_Block) return Boolean is
     (A0B.Callbacks.Is_Set (Event.Callback));

end A0B.Timer;