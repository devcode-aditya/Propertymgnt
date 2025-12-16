table 465 "Additional Approvers"
{
    // DP = changes made by DVS

    Caption = 'Additional Approvers';

    fields
    {
        field(1; "Approval Code"; Code[20])
        {
            Caption = 'Approval Code';
            TableRelation = "Approval Templates"."Approval Code";
        }
        field(2; "Approver ID"; Code[20])
        {
            Caption = 'Approver ID';
            TableRelation = "User Setup"."User ID";

            trigger OnValidate()
            var
                AddAppr: Record "465";
                ApprTemplate: Record "464";
            begin
                AddAppr.SETRANGE("Approval Code", "Approval Code");
                AddAppr.SETRANGE("Approval Type", "Approval Type");
                AddAppr.SETRANGE("Document Type", "Document Type");
                AddAppr.SETRANGE("Limit Type", "Limit Type");
                IF "Approver ID" <> '' THEN BEGIN
                    AddAppr.SETRANGE("Approver ID", "Approver ID");
                    IF AddAppr.FINDFIRST THEN
                        ERROR(STRSUBSTNO(Text001, AddAppr."Approver ID"));
                END ELSE BEGIN
                    AddAppr.SETFILTER("Approver ID", '<>%1&<>%2', '', xRec."Approver ID");
                    IF NOT AddAppr.FINDFIRST THEN
                        IF ApprTemplate.GET("Approval Code", "Approval Type", "Document Type", "Limit Type") THEN
                            IF ((ApprTemplate."Approval Type" = ApprTemplate."Approval Type"::" ") OR
                                (ApprTemplate."Limit Type" = ApprTemplate."Limit Type"::"Credit Limits")) AND ApprTemplate.Enabled
                            THEN
                                IF CONFIRM(STRSUBSTNO(Text002, AddAppr.TABLECAPTION)) THEN BEGIN
                                    ApprTemplate.VALIDATE(Enabled, FALSE);
                                    ApprTemplate.MODIFY;
                                END ELSE
                                    ERROR('');
                END;
            end;
        }
        field(3; "Approval Type"; Option)
        {
            Caption = 'Approval Type';
            OptionCaption = ' ,Sales Pers./Purchaser,Approver';
            OptionMembers = " ","Sales Pers./Purchaser",Approver;
        }
        field(4; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Description = 'DP6.01.01';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order,None,Lease,Sale,Work Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order","None",Lease,Sale,"Work Order";
        }
        field(5; "Limit Type"; Option)
        {
            Caption = 'Limit Type';
            Editable = false;
            OptionCaption = 'Approval Limits,Credit Limits,Request Limits,No Limits';
            OptionMembers = "Approval Limits","Credit Limits","Request Limits","No Limits";
        }
        field(6; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Approver ID", "Approval Code", "Approval Type", "Document Type", "Limit Type", "Sequence No.")
        {
            Clustered = true;
        }
        key(Key2; "Sequence No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AddAppr: Record "465";
        ApprTemplate: Record "464";
    begin
        AddAppr.SETRANGE("Approval Code", "Approval Code");
        AddAppr.SETRANGE("Approval Type", "Approval Type");
        AddAppr.SETRANGE("Document Type", "Document Type");
        AddAppr.SETRANGE("Limit Type", "Limit Type");
        AddAppr.SETFILTER("Approver ID", '<>%1&<>%2', '', "Approver ID");
        IF NOT AddAppr.FINDFIRST THEN
            IF ApprTemplate.GET("Approval Code", "Approval Type", "Document Type", "Limit Type") THEN
                IF ((ApprTemplate."Approval Type" = ApprTemplate."Approval Type"::" ") OR
                    (ApprTemplate."Limit Type" = ApprTemplate."Limit Type"::"Credit Limits")) AND ApprTemplate.Enabled
                THEN
                    IF CONFIRM(STRSUBSTNO(Text002, AddAppr.TABLECAPTION)) THEN BEGIN
                        ApprTemplate.VALIDATE(Enabled, FALSE);
                        ApprTemplate.MODIFY;
                    END ELSE
                        ERROR('');
    end;

    var
        Text001: Label 'Approver ID %1 is already an additional approver on this template.';
        Text002: Label 'The approval template will be disabled because no %1 are available.\Do you want to continue?';
}

