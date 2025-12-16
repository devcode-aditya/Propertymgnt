table 456 "Posted Approval Entry"
{
    // DP = changes made by DVS

    Caption = 'Posted Approval Entry';

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(5; "Approval Code"; Code[20])
        {
            Caption = 'Approval Code';
        }
        field(6; "Sender ID"; Code[20])
        {
            Caption = 'Sender ID';
        }
        field(7; "Salespers./Purch. Code"; Code[10])
        {
            Caption = 'Salespers./Purch. Code';
        }
        field(8; "Approver ID"; Code[20])
        {
            Caption = 'Approver ID';
        }
        field(9; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Created,Open,Canceled,Rejected,Approved';
            OptionMembers = Created,Open,Canceled,Rejected,Approved;
        }
        field(10; "Date-Time Sent for Approval"; DateTime)
        {
            Caption = 'Date-Time Sent for Approval';
        }
        field(11; "Last Date-Time Modified"; DateTime)
        {
            Caption = 'Last Date-Time Modified';
        }
        field(12; "Last Modified By ID"; Code[20])
        {
            Caption = 'Last Modified By ID';
        }
        field(13; Comment; Boolean)
        {
            CalcFormula = Exist ("Posted Approval Comment Line" WHERE (Table ID=FIELD(Table ID),
                                                                      Document No.=FIELD(Document No.)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14;"Due Date";Date)
        {
            Caption = 'Due Date';
        }
        field(15;Amount;Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(16;"Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(17;"Currency Code";Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(18;"Approval Type";Option)
        {
            Caption = 'Approval Type';
            OptionCaption = ' ,Sales Pers./Purchaser,Approver';
            OptionMembers = " ","Sales Pers./Purchaser",Approver;
        }
        field(19;"Limit Type";Option)
        {
            Caption = 'Limit Type';
            OptionCaption = 'Approval Limits,Credit Limits,Request Limits,No Limits';
            OptionMembers = "Approval Limits","Credit Limits","Request Limits","No Limits";
        }
        field(20;"Available Credit Limit (LCY)";Decimal)
        {
            Caption = 'Available Credit Limit (LCY)';
        }
        field(33016800;"Agreement Type";Option)
        {
            Description = 'DP6.01.01';
            OptionCaption = ' ,Agreement';
            OptionMembers = " ",Agreement;
        }
    }

    keys
    {
        key(Key1;"Table ID","Document No.","Sequence No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PostedApprovalComment: Record "457";
    begin
        PostedApprovalComment.SETRANGE("Entry No.","Table ID");
        PostedApprovalComment.SETRANGE("Document No.","Document No.");
        PostedApprovalComment.DELETEALL;
    end;
}

