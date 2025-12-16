codeunit 33016806 "PDC Management"
{

    trigger OnRun()
    begin
    end;

    procedure CreateAgrmtApplicationLines(RcptJnlLine: Record "81")
    var
        AgrmtApplicationLines: Record "33016871";
        PaymentSchduleLines: Record "33016824";
        NextLineNo: Integer;
        LastAgrmtApplicationLines: Record "33016871";
        AgrmtApplyEntries: Record "33016871";
        AgrmtApplyEntriesForm: Form "33016921";
        OK: Boolean;
        AmountApplied: Decimal;
        RcptJnlLine1: Record "81";
    begin
        LastAgrmtApplicationLines.RESET;
        LastAgrmtApplicationLines.SETRANGE("Journal Template Name", RcptJnlLine."Journal Template Name");
        LastAgrmtApplicationLines.SETRANGE("Journal Batch Name", RcptJnlLine."Journal Batch Name");
        LastAgrmtApplicationLines.SETRANGE("Journal Line No.", RcptJnlLine."Line No.");
        LastAgrmtApplicationLines.SETRANGE("Amount to Apply", 0);
        LastAgrmtApplicationLines.DELETEALL;

        LastAgrmtApplicationLines.RESET;
        IF LastAgrmtApplicationLines.FINDLAST THEN
            NextLineNo := LastAgrmtApplicationLines."Line No."
        ELSE
            NextLineNo := 0;

        PaymentSchduleLines.RESET;
        PaymentSchduleLines.SETCURRENTKEY("Agreement Type", "Agreement No.", "Agreement Line No.");
        PaymentSchduleLines.SETRANGE("Agreement Type", RcptJnlLine."Ref. Document Type");
        PaymentSchduleLines.SETRANGE("Agreement No.", RcptJnlLine."Ref. Document No.");
        PaymentSchduleLines.SETFILTER("Balance Amt.", '<>%1', 0);
        IF PaymentSchduleLines.FINDSET(FALSE, FALSE) THEN BEGIN
            REPEAT
                AgrmtApplicationLines.SETRANGE("Journal Template Name", RcptJnlLine."Journal Template Name");
                AgrmtApplicationLines.SETRANGE("Journal Batch Name", RcptJnlLine."Journal Batch Name");
                AgrmtApplicationLines.SETRANGE("Journal Line No.", RcptJnlLine."Line No.");
                AgrmtApplicationLines.SETRANGE("Ref. Document Type", RcptJnlLine."Ref. Document Type");
                AgrmtApplicationLines.SETRANGE("Ref. Document No.", RcptJnlLine."Ref. Document No.");
                AgrmtApplicationLines.SETRANGE("Ref. Document Line No.", PaymentSchduleLines."Agreement Line No.");
                AgrmtApplicationLines.SETRANGE("Payment Schedule Line No.", PaymentSchduleLines."Payment Schedule Line No.");
                IF NOT AgrmtApplicationLines.FINDFIRST THEN BEGIN
                    NextLineNo += 1;
                    AgrmtApplicationLines.INIT;
                    AgrmtApplicationLines."Journal Template Name" := RcptJnlLine."Journal Template Name";
                    AgrmtApplicationLines."Journal Batch Name" := RcptJnlLine."Journal Batch Name";
                    AgrmtApplicationLines."Journal Line No." := RcptJnlLine."Line No.";
                    AgrmtApplicationLines."Ref. Document Type" := RcptJnlLine."Ref. Document Type";
                    AgrmtApplicationLines."Ref. Document No." := RcptJnlLine."Ref. Document No.";
                    AgrmtApplicationLines."Ref. Document Line No." := PaymentSchduleLines."Agreement Line No.";
                    AgrmtApplicationLines."Document No." := RcptJnlLine."Document No.";
                    AgrmtApplicationLines."Payment Schedule Line No." := PaymentSchduleLines."Payment Schedule Line No.";
                    AgrmtApplicationLines."Line No." := NextLineNo;
                    AgrmtApplicationLines."Invoice Due Amt." := PaymentSchduleLines."Invoice Due Amt.";
                    AgrmtApplicationLines."Element Type" := PaymentSchduleLines."Element Type";
                    AgrmtApplicationLines."Due Date" := PaymentSchduleLines."Due Date";
                    AgrmtApplicationLines.Description := PaymentSchduleLines.Description;
                    AgrmtApplicationLines."Applied Amount" := PaymentSchduleLines."Amount Paid";
                    AgrmtApplicationLines."Remaining Amt." := PaymentSchduleLines."Balance Amt.";
                    AgrmtApplicationLines.INSERT;
                END;
            UNTIL PaymentSchduleLines.NEXT = 0;
        END;

        COMMIT;
        AgrmtApplyEntries.RESET;
        AgrmtApplyEntries.SETCURRENTKEY("Journal Template Name", "Journal Batch Name", "Journal Line No.");
        AgrmtApplyEntries.SETRANGE("Journal Template Name", RcptJnlLine."Journal Template Name");
        AgrmtApplyEntries.SETRANGE("Journal Batch Name", RcptJnlLine."Journal Batch Name");
        AgrmtApplyEntries.SETRANGE("Journal Line No.", RcptJnlLine."Line No.");

        CLEAR(AgrmtApplyEntriesForm);
        AgrmtApplyEntriesForm.SETRECORD(AgrmtApplyEntries);
        AgrmtApplyEntriesForm.SETTABLEVIEW(AgrmtApplyEntries);
        AgrmtApplyEntriesForm.LOOKUPMODE(TRUE);
        OK := AgrmtApplyEntriesForm.RUNMODAL = ACTION::LookupOK;
        CLEAR(AgrmtApplyEntriesForm);

        AgrmtApplyEntries.RESET;
        AgrmtApplyEntries.SETCURRENTKEY("Journal Template Name", "Journal Batch Name", "Journal Line No.");
        AgrmtApplyEntries.SETRANGE("Journal Template Name", RcptJnlLine."Journal Template Name");
        AgrmtApplyEntries.SETRANGE("Journal Batch Name", RcptJnlLine."Journal Batch Name");
        AgrmtApplyEntries.SETRANGE("Journal Line No.", RcptJnlLine."Line No.");
        AgrmtApplyEntries.SETRANGE("Amount to Apply", 0);
        AgrmtApplyEntries.DELETEALL;

        AmountApplied := 0;

        AgrmtApplyEntries.RESET;
        AgrmtApplyEntries.SETCURRENTKEY("Journal Template Name", "Journal Batch Name", "Journal Line No.");
        AgrmtApplyEntries.SETRANGE("Journal Template Name", RcptJnlLine."Journal Template Name");
        AgrmtApplyEntries.SETRANGE("Journal Batch Name", RcptJnlLine."Journal Batch Name");
        AgrmtApplyEntries.SETRANGE("Journal Line No.", RcptJnlLine."Line No.");
        AgrmtApplyEntries.SETFILTER("Amount to Apply", '<>%1', 0);
        IF AgrmtApplyEntries.FINDSET THEN BEGIN
            REPEAT
                AmountApplied += AgrmtApplyEntries."Amount to Apply";
            UNTIL AgrmtApplyEntries.NEXT = 0;
        END;
        RcptJnlLine1 := RcptJnlLine;
        RcptJnlLine1."Applied Agrmt. Amount" := AmountApplied;
        RcptJnlLine1.MODIFY;

        IF NOT OK THEN
            EXIT;
    end;

    procedure InsertAppliedAgrmtEntries(RptJnlApprovedLine: Record "81")
    var
        AgrmtApplicationEntries: Record "33016872";
        ApplyEntries: Record "33016871";
        PaymentSchdule: Record "33016824";
        NextEntryNo: Integer;
    begin
        IF AgrmtApplicationEntries.FINDLAST THEN
            NextEntryNo := AgrmtApplicationEntries."Entry No."
        ELSE
            NextEntryNo := 0;

        ApplyEntries.SETRANGE("Journal Template Name", RptJnlApprovedLine."Journal Template Name");
        ApplyEntries.SETRANGE("Journal Batch Name", RptJnlApprovedLine."Journal Batch Name");
        ApplyEntries.SETRANGE("Journal Line No.", RptJnlApprovedLine."Line No.");
        ApplyEntries.SETRANGE("Document No.", RptJnlApprovedLine."Document No.");
        IF ApplyEntries.FINDSET THEN BEGIN
            REPEAT
                NextEntryNo += 1;
                AgrmtApplicationEntries.INIT;
                AgrmtApplicationEntries."Journal Template Name" := ApplyEntries."Journal Template Name";
                AgrmtApplicationEntries."Journal Batch Name" := ApplyEntries."Journal Batch Name";
                AgrmtApplicationEntries."Journal Line No." := ApplyEntries."Journal Line No.";
                AgrmtApplicationEntries."Ref. Document Type" := ApplyEntries."Ref. Document Type";
                AgrmtApplicationEntries."Ref. Document No." := ApplyEntries."Ref. Document No.";
                AgrmtApplicationEntries."Ref. Document Line No." := ApplyEntries."Ref. Document Line No.";
                AgrmtApplicationEntries."Payment Schedule Line No." := ApplyEntries."Payment Schedule Line No.";
                AgrmtApplicationEntries."Entry No." := NextEntryNo;
                AgrmtApplicationEntries."Document No." := ApplyEntries."Document No.";
                AgrmtApplicationEntries."Entry Type" := AgrmtApplicationEntries."Entry Type"::Approved;
                AgrmtApplicationEntries."Invoice Due Amt." := ApplyEntries."Invoice Due Amt.";
                AgrmtApplicationEntries."Element Type" := ApplyEntries."Element Type";
                AgrmtApplicationEntries.Description := ApplyEntries.Description;
                AgrmtApplicationEntries."Applied Amount" := ApplyEntries."Amount to Apply";
                AgrmtApplicationEntries."Due Date" := ApplyEntries."Due Date";
                AgrmtApplicationEntries.INSERT;

                PaymentSchdule.RESET;
                PaymentSchdule.SETRANGE("Agreement Type", ApplyEntries."Ref. Document Type");
                PaymentSchdule.SETRANGE("Agreement No.", ApplyEntries."Ref. Document No.");
                PaymentSchdule.SETRANGE("Agreement Line No.", ApplyEntries."Ref. Document Line No.");
                PaymentSchdule.SETRANGE("Payment Schedule Line No.", ApplyEntries."Payment Schedule Line No.");
                IF PaymentSchdule.FINDFIRST THEN BEGIN
                    PaymentSchdule."Amount Paid" += ApplyEntries."Amount to Apply";
                    PaymentSchdule."Balance Amt." := PaymentSchdule."Balance Amt." - ApplyEntries."Amount to Apply";
                    PaymentSchdule.MODIFY;
                END;
            UNTIL ApplyEntries.NEXT = 0;
        END;

        ApplyEntries.RESET;
        ApplyEntries.SETRANGE("Journal Template Name", RptJnlApprovedLine."Journal Template Name");
        ApplyEntries.SETRANGE("Journal Batch Name", RptJnlApprovedLine."Journal Batch Name");
        ApplyEntries.SETRANGE("Journal Line No.", RptJnlApprovedLine."Line No.");
        ApplyEntries.DELETEALL;
    end;

    procedure EditAppliedAgrmtEntries(RptJnlEditLine: Record "81")
    var
        AgrmtApplicationEntries: Record "33016872";
        ApplyEntries: Record "33016871";
        PaymentSchdule: Record "33016824";
        NextEntryNo: Integer;
    begin
        IF ApplyEntries.FINDLAST THEN
            NextEntryNo := ApplyEntries."Line No."
        ELSE
            NextEntryNo := 0;

        AgrmtApplicationEntries.SETRANGE("Journal Template Name", RptJnlEditLine."Journal Template Name");
        AgrmtApplicationEntries.SETRANGE("Journal Batch Name", RptJnlEditLine."Journal Batch Name");
        AgrmtApplicationEntries.SETRANGE("Journal Line No.", RptJnlEditLine."Line No.");
        AgrmtApplicationEntries.SETRANGE("Document No.", RptJnlEditLine."Document No.");
        AgrmtApplicationEntries.SETRANGE("Ref. Document Type", RptJnlEditLine."Ref. Document Type");
        AgrmtApplicationEntries.SETRANGE("Ref. Document No.", RptJnlEditLine."Ref. Document No.");
        AgrmtApplicationEntries.SETRANGE("Entry Type", AgrmtApplicationEntries."Entry Type"::Approved);
        IF AgrmtApplicationEntries.FINDSET THEN BEGIN
            REPEAT
                NextEntryNo += 1;
                ApplyEntries.INIT;
                ApplyEntries."Journal Template Name" := AgrmtApplicationEntries."Journal Template Name";
                ApplyEntries."Journal Batch Name" := AgrmtApplicationEntries."Journal Batch Name";
                ApplyEntries."Journal Line No." := AgrmtApplicationEntries."Journal Line No.";
                ApplyEntries."Ref. Document Type" := AgrmtApplicationEntries."Ref. Document Type";
                ApplyEntries."Ref. Document No." := AgrmtApplicationEntries."Ref. Document No.";
                ApplyEntries."Ref. Document Line No." := AgrmtApplicationEntries."Ref. Document Line No.";
                ApplyEntries."Payment Schedule Line No." := AgrmtApplicationEntries."Payment Schedule Line No.";
                ApplyEntries."Line No." := NextEntryNo;
                ApplyEntries."Document No." := AgrmtApplicationEntries."Document No.";
                ApplyEntries."Invoice Due Amt." := AgrmtApplicationEntries."Invoice Due Amt.";
                ApplyEntries."Due Date" := AgrmtApplicationEntries."Due Date";
                ApplyEntries."Element Type" := AgrmtApplicationEntries."Element Type";
                ApplyEntries.Description := AgrmtApplicationEntries.Description;
                ApplyEntries."Amount to Apply" := AgrmtApplicationEntries."Applied Amount";
                ApplyEntries.INSERT;

                PaymentSchdule.RESET;
                PaymentSchdule.SETRANGE("Agreement Type", ApplyEntries."Ref. Document Type");
                PaymentSchdule.SETRANGE("Agreement No.", ApplyEntries."Ref. Document No.");
                PaymentSchdule.SETRANGE("Agreement Line No.", ApplyEntries."Ref. Document Line No.");
                PaymentSchdule.SETRANGE("Payment Schedule Line No.", ApplyEntries."Payment Schedule Line No.");
                IF PaymentSchdule.FINDFIRST THEN BEGIN
                    PaymentSchdule."Amount Paid" := PaymentSchdule."Amount Paid" - AgrmtApplicationEntries."Applied Amount";
                    PaymentSchdule."Balance Amt." := PaymentSchdule."Balance Amt." + AgrmtApplicationEntries."Applied Amount";
                    PaymentSchdule.MODIFY;

                    ApplyEntries."Applied Amount" := PaymentSchdule."Amount Paid";
                    ApplyEntries."Remaining Amt." := PaymentSchdule."Balance Amt.";
                    ApplyEntries.MODIFY;
                END;
            UNTIL AgrmtApplicationEntries.NEXT = 0;
        END;

        AgrmtApplicationEntries.RESET;
        AgrmtApplicationEntries.SETRANGE("Journal Template Name", RptJnlEditLine."Journal Template Name");
        AgrmtApplicationEntries.SETRANGE("Journal Batch Name", RptJnlEditLine."Journal Batch Name");
        AgrmtApplicationEntries.SETRANGE("Journal Line No.", RptJnlEditLine."Line No.");
        AgrmtApplicationEntries.SETRANGE("Document No.", RptJnlEditLine."Document No.");
        AgrmtApplicationEntries.SETRANGE("Ref. Document Type", RptJnlEditLine."Ref. Document Type");
        AgrmtApplicationEntries.SETRANGE("Ref. Document No.", RptJnlEditLine."Ref. Document No.");
        AgrmtApplicationEntries.SETRANGE("Entry Type", AgrmtApplicationEntries."Entry Type"::Approved);
        AgrmtApplicationEntries.DELETEALL;
    end;

    procedure ProcessAppliedAgrmtEntries(RcptJnlTemplate: Code[10]; RcptJnlBatch: Code[10]; RcptJnlLineNo: Integer; ProcessedRcptJnlLine: Record "81")
    var
        AgrmtApplicationEntries: Record "33016872";
        ProcessedAgrmtApplEntries: Record "33016872";
        NextEntryNo: Integer;
    begin
        IF ProcessedAgrmtApplEntries.FINDLAST THEN
            NextEntryNo := ProcessedAgrmtApplEntries."Entry No."
        ELSE
            NextEntryNo := 0;

        AgrmtApplicationEntries.SETRANGE("Journal Template Name", RcptJnlTemplate);
        AgrmtApplicationEntries.SETRANGE("Journal Batch Name", RcptJnlBatch);
        AgrmtApplicationEntries.SETRANGE("Journal Line No.", RcptJnlLineNo);
        AgrmtApplicationEntries.SETRANGE("Document No.", ProcessedRcptJnlLine."Document No.");
        AgrmtApplicationEntries.SETRANGE("Ref. Document Type", ProcessedRcptJnlLine."Ref. Document Type");
        AgrmtApplicationEntries.SETRANGE("Ref. Document No.", ProcessedRcptJnlLine."Ref. Document No.");
        AgrmtApplicationEntries.SETRANGE("Entry Type", AgrmtApplicationEntries."Entry Type"::Approved);
        IF AgrmtApplicationEntries.FINDSET THEN BEGIN
            REPEAT
                NextEntryNo += 1;
                ProcessedAgrmtApplEntries.INIT;
                ProcessedAgrmtApplEntries."Journal Template Name" := ProcessedRcptJnlLine."Journal Template Name";
                ProcessedAgrmtApplEntries."Journal Batch Name" := ProcessedRcptJnlLine."Journal Batch Name";
                ProcessedAgrmtApplEntries."Journal Line No." := ProcessedRcptJnlLine."Line No.";
                ProcessedAgrmtApplEntries."Ref. Document Type" := ProcessedRcptJnlLine."Ref. Document Type";
                ProcessedAgrmtApplEntries."Ref. Document No." := ProcessedRcptJnlLine."Ref. Document No.";
                ProcessedAgrmtApplEntries."Ref. Document Line No." := AgrmtApplicationEntries."Ref. Document Line No.";
                ProcessedAgrmtApplEntries."Payment Schedule Line No." := AgrmtApplicationEntries."Payment Schedule Line No.";
                ProcessedAgrmtApplEntries."Entry No." := NextEntryNo;
                ProcessedAgrmtApplEntries."Document No." := AgrmtApplicationEntries."Document No.";
                ProcessedAgrmtApplEntries."Entry Type" := ProcessedAgrmtApplEntries."Entry Type"::Processed;
                ProcessedAgrmtApplEntries."Invoice Due Amt." := AgrmtApplicationEntries."Invoice Due Amt.";
                ProcessedAgrmtApplEntries."Due Date" := AgrmtApplicationEntries."Due Date";
                ProcessedAgrmtApplEntries."Element Type" := AgrmtApplicationEntries."Element Type";
                ProcessedAgrmtApplEntries.Description := AgrmtApplicationEntries.Description;
                ProcessedAgrmtApplEntries."Applied Amount" := AgrmtApplicationEntries."Applied Amount";
                ProcessedAgrmtApplEntries.INSERT;
            UNTIL AgrmtApplicationEntries.NEXT = 0;
        END;

        AgrmtApplicationEntries.RESET;
        AgrmtApplicationEntries.SETRANGE("Journal Template Name", RcptJnlTemplate);
        AgrmtApplicationEntries.SETRANGE("Journal Batch Name", RcptJnlBatch);
        AgrmtApplicationEntries.SETRANGE("Journal Line No.", RcptJnlLineNo);
        AgrmtApplicationEntries.SETRANGE("Document No.", ProcessedRcptJnlLine."Document No.");
        AgrmtApplicationEntries.SETRANGE("Ref. Document Type", ProcessedRcptJnlLine."Ref. Document Type");
        AgrmtApplicationEntries.SETRANGE("Ref. Document No.", ProcessedRcptJnlLine."Ref. Document No.");
        AgrmtApplicationEntries.SETRANGE("Entry Type", AgrmtApplicationEntries."Entry Type"::Approved);
        AgrmtApplicationEntries.DELETEALL;
    end;

    procedure UnProcessAppliedAgrmtEntries(ProcessedRcptJnlLine: Record "81"; UnProcessedRcptJnlLine: Record "81")
    var
        AgrmtApplicationEntries: Record "33016872";
        ProcessedAgrmtApplEntries: Record "33016872";
        NextEntryNo: Integer;
    begin
        IF ProcessedAgrmtApplEntries.FINDLAST THEN
            NextEntryNo := ProcessedAgrmtApplEntries."Entry No."
        ELSE
            NextEntryNo := 0;

        AgrmtApplicationEntries.SETRANGE("Journal Template Name", ProcessedRcptJnlLine."Journal Template Name");
        AgrmtApplicationEntries.SETRANGE("Journal Batch Name", ProcessedRcptJnlLine."Journal Batch Name");
        AgrmtApplicationEntries.SETRANGE("Journal Line No.", ProcessedRcptJnlLine."Line No.");
        AgrmtApplicationEntries.SETRANGE("Document No.", ProcessedRcptJnlLine."Document No.");
        AgrmtApplicationEntries.SETRANGE("Ref. Document Type", ProcessedRcptJnlLine."Ref. Document Type");
        AgrmtApplicationEntries.SETRANGE("Ref. Document No.", ProcessedRcptJnlLine."Ref. Document No.");
        AgrmtApplicationEntries.SETRANGE("Entry Type", AgrmtApplicationEntries."Entry Type"::Processed);
        IF AgrmtApplicationEntries.FINDSET THEN BEGIN
            REPEAT
                NextEntryNo += 1;
                ProcessedAgrmtApplEntries.INIT;
                ProcessedAgrmtApplEntries."Journal Template Name" := UnProcessedRcptJnlLine."Journal Template Name";
                ProcessedAgrmtApplEntries."Journal Batch Name" := UnProcessedRcptJnlLine."Journal Batch Name";
                ProcessedAgrmtApplEntries."Journal Line No." := UnProcessedRcptJnlLine."Line No.";
                ProcessedAgrmtApplEntries."Ref. Document Type" := UnProcessedRcptJnlLine."Ref. Document Type";
                ProcessedAgrmtApplEntries."Ref. Document No." := UnProcessedRcptJnlLine."Ref. Document No.";
                ProcessedAgrmtApplEntries."Ref. Document Line No." := AgrmtApplicationEntries."Ref. Document Line No.";
                ProcessedAgrmtApplEntries."Payment Schedule Line No." := AgrmtApplicationEntries."Payment Schedule Line No.";
                ProcessedAgrmtApplEntries."Entry No." := NextEntryNo;
                ProcessedAgrmtApplEntries."Document No." := AgrmtApplicationEntries."Document No.";
                ProcessedAgrmtApplEntries."Entry Type" := AgrmtApplicationEntries."Entry Type"::Approved;
                ProcessedAgrmtApplEntries."Invoice Due Amt." := AgrmtApplicationEntries."Invoice Due Amt.";
                ProcessedAgrmtApplEntries."Due Date" := AgrmtApplicationEntries."Due Date";
                ProcessedAgrmtApplEntries."Element Type" := AgrmtApplicationEntries."Element Type";
                ProcessedAgrmtApplEntries.Description := AgrmtApplicationEntries.Description;
                ProcessedAgrmtApplEntries."Applied Amount" := AgrmtApplicationEntries."Applied Amount";
                ProcessedAgrmtApplEntries.INSERT;
            UNTIL AgrmtApplicationEntries.NEXT = 0;
        END;

        AgrmtApplicationEntries.RESET;
        AgrmtApplicationEntries.SETRANGE("Journal Template Name", ProcessedRcptJnlLine."Journal Template Name");
        AgrmtApplicationEntries.SETRANGE("Journal Batch Name", ProcessedRcptJnlLine."Journal Batch Name");
        AgrmtApplicationEntries.SETRANGE("Journal Line No.", ProcessedRcptJnlLine."Line No.");
        AgrmtApplicationEntries.SETRANGE("Document No.", ProcessedRcptJnlLine."Document No.");
        AgrmtApplicationEntries.SETRANGE("Ref. Document Type", ProcessedRcptJnlLine."Ref. Document Type");
        AgrmtApplicationEntries.SETRANGE("Ref. Document No.", ProcessedRcptJnlLine."Ref. Document No.");
        AgrmtApplicationEntries.SETRANGE("Entry Type", AgrmtApplicationEntries."Entry Type"::Processed);
        AgrmtApplicationEntries.DELETEALL;
    end;

    procedure PostedAppliedAgrmtEntries(PostedRcptJnlLine: Record "81")
    var
        AgrmtApplicationEntries: Record "33016872";
        PostedAgrmtApplEntries: Record "33016872";
        NextEntryNo: Integer;
    begin
        IF PostedAgrmtApplEntries.FINDLAST THEN
            NextEntryNo := PostedAgrmtApplEntries."Entry No."
        ELSE
            NextEntryNo := 0;

        AgrmtApplicationEntries.SETRANGE("Journal Template Name", PostedRcptJnlLine."Journal Template Name");
        AgrmtApplicationEntries.SETRANGE("Journal Batch Name", PostedRcptJnlLine."Journal Batch Name");
        AgrmtApplicationEntries.SETRANGE("Journal Line No.", PostedRcptJnlLine."Line No.");
        AgrmtApplicationEntries.SETRANGE("Document No.", PostedRcptJnlLine."Document No.");
        AgrmtApplicationEntries.SETRANGE("Ref. Document Type", PostedRcptJnlLine."Ref. Document Type");
        AgrmtApplicationEntries.SETRANGE("Ref. Document No.", PostedRcptJnlLine."Ref. Document No.");
        AgrmtApplicationEntries.SETRANGE("Entry Type", AgrmtApplicationEntries."Entry Type"::Processed);
        IF AgrmtApplicationEntries.FINDSET THEN BEGIN
            REPEAT
                PostedAgrmtApplEntries := AgrmtApplicationEntries;
                PostedAgrmtApplEntries."Entry Type" := PostedAgrmtApplEntries."Entry Type"::Posted;
                PostedAgrmtApplEntries.MODIFY;
            UNTIL AgrmtApplicationEntries.NEXT = 0;
        END;
    end;
}

