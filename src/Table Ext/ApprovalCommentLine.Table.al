table 455 "Approval Comment Line"
{
    // DP = changed made by DVS

    Caption = 'Approval Comment Line';
    DrillDownFormID = Form660;
    LookupFormID = Form660;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            Editable = false;
        }
        field(3; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Description = 'DP6.01.01';
            Editable = false;
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order,Lease,Sale,Work Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Lease,Sale,"Work Order";
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(5; "User ID"; Code[20])
        {
            Caption = 'User ID';
            Editable = false;
        }
        field(6; "Date and Time"; DateTime)
        {
            Caption = 'Date and Time';
            Editable = false;
        }
        field(7; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Table ID", "Document Type", "Document No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "User ID" := USERID;
        "Date and Time" := CREATEDATETIME(TODAY, TIME);
        IF "Entry No." = 0 THEN
            "Entry No." := GetNextEntryNo;
    end;

    local procedure GetNextEntryNo(): Integer
    var
        ApprovalCommentLine: Record "455";
    begin
        ApprovalCommentLine.SETCURRENTKEY("Entry No.");
        IF ApprovalCommentLine.FIND('+') THEN
            EXIT(ApprovalCommentLine."Entry No." + 1)
        ELSE
            EXIT(1);
    end;
}

