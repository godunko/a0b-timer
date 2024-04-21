--
--  Copyright (C) 2024, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  pragma Restrictions (No_Elaboration_Code);

with A0B.Time.Constants;
with A0B.Time.Clock;

package body A0B.Timer is

   use type A0B.Time.Monotonic_Time;

   package Platform is

      procedure Disable_Interrupts with Inline_Always;

      procedure Enable_Interrupts with Inline_Always;

      procedure Request_Tick;

      procedure Set_Next
        (Span    : A0B.Time.Time_Span;
         Success : out Boolean);
      --  Configure timer to issue next tick.
      --
      --  @param Success
      --  Set to True when timer is set successfull, and False when given span
      --  is not distinguishable by the timer implementation from "now".

   end Platform;

   procedure Internal_Enqueue (Event : not null Timeout_Control_Block_Access);

   procedure Internal_Dequeue
     (Event : out Timeout_Control_Block_Access;
      Now   : A0B.Time.Monotonic_Time);

   Head : aliased Timeout_Control_Block;
   Tail : aliased Timeout_Control_Block;
   --  Head and tail of the timer's queue.

   ------------
   -- Cancel --
   ------------

   procedure Cancel (Event : aliased in out Timeout_Control_Block) is
   begin
      Platform.Disable_Interrupts;

      declare
         Previous : Timeout_Control_Block_Access := Head'Access;

      begin
         --  Cleanup callback.

         A0B.Callbacks.Unset (Event.Callback);

         --  Remove from the queue.

         loop
            --  exit when Previous.Next = null;

            exit when Previous.Next = Event'Unchecked_Access;

            Previous := Previous.Next;
         end loop;

         Previous.Next := Event.Next;

         Event.Time_Stamp := A0B.Time.Constants.Monotonic_Time_First;
         --  A0B.Callbacks.Unset (Event.Callback);
         Event.Next       := null;
      end;

      Platform.Enable_Interrupts;
   end Cancel;

   -------------
   -- Enqueue --
   -------------

   procedure Enqueue
     (Event    : aliased in out Timeout_Control_Block;
      Callback : A0B.Callbacks.Callback;
      T        : A0B.Time.Duration) is
   begin
      pragma Assert (A0B.Callbacks.Is_Set (Callback));

      Event.Time_Stamp := A0B.Time.Clock + A0B.Time.To_Time_Span (T);
      Event.Callback   := Callback;

      Internal_Enqueue (Event'Unchecked_Access);
   end Enqueue;

   -------------
   -- Enqueue --
   -------------

   procedure Enqueue
     (Event    : aliased in out Timeout_Control_Block;
      Callback : A0B.Callbacks.Callback;
      T        : A0B.Time.Time_Span) is
   begin
      pragma Assert (A0B.Callbacks.Is_Set (Callback));

      Event.Time_Stamp := A0B.Time.Clock + T;
      Event.Callback   := Callback;

      Internal_Enqueue (Event'Unchecked_Access);
   end Enqueue;

   -------------
   -- Enqueue --
   -------------

   procedure Enqueue
     (Event    : aliased in out Timeout_Control_Block;
      Callback : A0B.Callbacks.Callback;
      T        : A0B.Time.Monotonic_Time) is
   begin
      pragma Assert (A0B.Callbacks.Is_Set (Callback));

      Event.Time_Stamp := T;
      Event.Callback   := Callback;

      Internal_Enqueue (Event'Unchecked_Access);
   end Enqueue;

   ----------------------
   -- Internal_Dequeue --
   ----------------------

   procedure Internal_Dequeue
     (Event : out Timeout_Control_Block_Access;
      Now   : A0B.Time.Monotonic_Time)
   is
      First   : constant not null Timeout_Control_Block_Access := Head.Next;
      Success : Boolean;

   begin
      --  Check whether queue is empty and return immidiately.

      if Head.Next = Tail'Access then
         Event := null;

         return;
      end if;

      --  Check that time stamp of the first element passed, remove it from
      --  the queue and return it.

      if First.Time_Stamp <= Now then
         Head.Next  := First.Next;
         First.Next := null;
         Event      := First;

         return;
      end if;

      --  Setup timer.

      Platform.Set_Next (First.Time_Stamp - Now, Success);

      if Success then
         Event := null;

      else
         Head.Next  := First.Next;
         First.Next := null;
         Event      := First;
      end if;
   end Internal_Dequeue;

   ----------------------
   -- Internal_Enqueue --
   ----------------------

   procedure Internal_Enqueue
     (Event : not null Timeout_Control_Block_Access) is
   begin
      Platform.Disable_Interrupts;

      declare
         Previous : not null Timeout_Control_Block_Access := Head'Access;

      begin
         --  Add to the queue

         loop
            exit when Previous.Next.Time_Stamp > Event.Time_Stamp;

            Previous := Previous.Next;
         end loop;

         Event.Next    := Previous.Next;
         Previous.Next := Event;

         if Head.Next = Event then
            Platform.Request_Tick;
         end if;
      end;

      Platform.Enable_Interrupts;
   end Internal_Enqueue;

   -------------------------
   -- Internal_Initialize --
   -------------------------

   procedure Internal_Initialize is
   begin
      Head.Time_Stamp := A0B.Time.Constants.Monotonic_Time_First;
      Head.Next       := Tail'Access;
      Tail.Time_Stamp := A0B.Time.Constants.Monotonic_Time_Last;
   end Internal_Initialize;

   ----------------------
   -- Internal_On_Tick --
   ----------------------

   procedure Internal_On_Tick is
      Event    : Timeout_Control_Block_Access;
      Callback : A0B.Callbacks.Callback;

   begin
      loop
         Internal_Dequeue (Event, A0B.Time.Clock);

         exit when Event = null;

         Callback := Event.Callback;

         A0B.Callbacks.Unset (Event.Callback);
         Event.Time_Stamp := A0B.Time.Constants.Monotonic_Time_First;
         Event.Next       := null;

         A0B.Callbacks.Emit (Callback);
      end loop;
   end Internal_On_Tick;

   --------------
   -- Platform --
   --------------

   package body Platform is separate;

end A0B.Timer;