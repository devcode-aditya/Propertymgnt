table 33016826 "Premise Management Setup"
{
    // APNT-T018890  16Jan18   Ajay            Modification for VAT Sale Invoice

    Caption = 'Premise Management Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Editable = false;
        }
        field(2; "Agreement Reason Code"; Code[10])
        {
            TableRelation = "Reason Code".Code;
        }
        field(3; "Sub-Unit Profile"; Code[20])
        {
        }
        field(4; Agreement; Code[10])
        {
            TableRelation = "No. Series";
        }
        field(5; Premise; Code[10])
        {
            TableRelation = "No. Series";
        }
        field(6; "Sub-premise"; Code[10])
        {
            TableRelation = "No. Series";
        }
        field(7; "Call Register"; Code[10])
        {
            TableRelation = "No. Series";
        }
        field(8; "Work Order"; Code[10])
        {
            TableRelation = "No. Series";
        }
        field(9; "Premise Attributes"; Code[20])
        {
        }
        field(10; "Questionnaire-Code1"; Code[20])
        {
            Caption = 'Questionnaire-Code1';
            TableRelation = "Profile Questionnaire Header".Code;

            trigger OnValidate()
            begin
                IF ProfileQuestionHeader.GET("Questionnaire-Code1") THEN BEGIN
                    IF "Questionnaire-Code1" <> '' THEN BEGIN
                        IF ("Questionnaire-Code1" = "Questionnaire-Code2") THEN
                            ERROR(Text001, "Questionnaire-Code1")
                        ELSE
                            IF ("Questionnaire-Code1" = "Questionnaire-Code3") THEN
                                ERROR(Text001, "Questionnaire-Code1")
                            ELSE
                                IF ("Questionnaire-Code1" = "Questionnaire-Code4") THEN
                                    ERROR(Text001, "Questionnaire-Code1")
                                ELSE
                                    IF ("Questionnaire-Code1" = "Questionnaire-Code5") THEN
                                        ERROR(Text001, "Questionnaire-Code1")
                                    ELSE
                                        IF ("Questionnaire-Code1" = "Questionnaire-Code6") THEN
                                            ERROR(Text001, "Questionnaire-Code1")
                                        ELSE
                                            IF ("Questionnaire-Code1" = "Questionnaire-Code7") THEN
                                                ERROR(Text001, "Questionnaire-Code1")
                                            ELSE
                                                IF ("Questionnaire-Code1" = "Questionnaire-Code8") THEN
                                                    ERROR(Text001, "Questionnaire-Code1")
                    END;
                    "Questionnaire-Desc1" := ProfileQuestionHeader.Description
                END ELSE
                    "Questionnaire-Desc1" := '';
            end;
        }
        field(11; "Questionnaire-Code2"; Code[20])
        {
            Caption = 'Questionnaire-Code2';
            TableRelation = "Profile Questionnaire Header".Code;

            trigger OnValidate()
            begin
                IF ProfileQuestionHeader.GET("Questionnaire-Code2") THEN BEGIN
                    IF "Questionnaire-Code2" <> '' THEN BEGIN
                        IF ("Questionnaire-Code2" = "Questionnaire-Code1") THEN
                            ERROR(Text001, "Questionnaire-Code2")
                        ELSE
                            IF ("Questionnaire-Code2" = "Questionnaire-Code3") THEN
                                ERROR(Text001, "Questionnaire-Code2")
                            ELSE
                                IF ("Questionnaire-Code2" = "Questionnaire-Code4") THEN
                                    ERROR(Text001, "Questionnaire-Code2")
                                ELSE
                                    IF ("Questionnaire-Code2" = "Questionnaire-Code5") THEN
                                        ERROR(Text001, "Questionnaire-Code2")
                                    ELSE
                                        IF ("Questionnaire-Code2" = "Questionnaire-Code6") THEN
                                            ERROR(Text001, "Questionnaire-Code2")
                                        ELSE
                                            IF ("Questionnaire-Code2" = "Questionnaire-Code7") THEN
                                                ERROR(Text001, "Questionnaire-Code2")
                                            ELSE
                                                IF ("Questionnaire-Code2" = "Questionnaire-Code8") THEN
                                                    ERROR(Text001, "Questionnaire-Code2");
                    END;
                    "Questionnaire-Desc2" := ProfileQuestionHeader.Description;
                END ELSE
                    "Questionnaire-Desc2" := '';
            end;
        }
        field(12; "Questionnaire-Code3"; Code[20])
        {
            Caption = 'Questionnaire-Code3';
            TableRelation = "Profile Questionnaire Header".Code;

            trigger OnValidate()
            begin
                IF ProfileQuestionHeader.GET("Questionnaire-Code3") THEN BEGIN
                    IF "Questionnaire-Code3" <> '' THEN BEGIN
                        IF ("Questionnaire-Code3" = "Questionnaire-Code1") THEN
                            ERROR(Text001, "Questionnaire-Code3")
                        ELSE
                            IF ("Questionnaire-Code3" = "Questionnaire-Code2") THEN
                                ERROR(Text001, "Questionnaire-Code3")
                            ELSE
                                IF ("Questionnaire-Code3" = "Questionnaire-Code4") THEN
                                    ERROR(Text001, "Questionnaire-Code3")
                                ELSE
                                    IF ("Questionnaire-Code3" = "Questionnaire-Code5") THEN
                                        ERROR(Text001, "Questionnaire-Code3")
                                    ELSE
                                        IF ("Questionnaire-Code3" = "Questionnaire-Code6") THEN
                                            ERROR(Text001, "Questionnaire-Code3")
                                        ELSE
                                            IF ("Questionnaire-Code3" = "Questionnaire-Code7") THEN
                                                ERROR(Text001, "Questionnaire-Code3")
                                            ELSE
                                                IF ("Questionnaire-Code3" = "Questionnaire-Code8") THEN
                                                    ERROR(Text001, "Questionnaire-Code3");
                    END;
                    "Questionnaire-Desc3" := ProfileQuestionHeader.Description
                END ELSE
                    "Questionnaire-Desc3" := '';
            end;
        }
        field(13; "Questionnaire-Code4"; Code[20])
        {
            Caption = 'Questionnaire-Code4';
            TableRelation = "Profile Questionnaire Header".Code;

            trigger OnValidate()
            begin
                IF ProfileQuestionHeader.GET("Questionnaire-Code4") THEN BEGIN
                    IF "Questionnaire-Code4" <> '' THEN BEGIN
                        IF ("Questionnaire-Code4" = "Questionnaire-Code1") THEN
                            ERROR(Text001, "Questionnaire-Code4")
                        ELSE
                            IF ("Questionnaire-Code4" = "Questionnaire-Code2") THEN
                                ERROR(Text001, "Questionnaire-Code4")
                            ELSE
                                IF ("Questionnaire-Code4" = "Questionnaire-Code3") THEN
                                    ERROR(Text001, "Questionnaire-Code4")
                                ELSE
                                    IF ("Questionnaire-Code4" = "Questionnaire-Code5") THEN
                                        ERROR(Text001, "Questionnaire-Code4")
                                    ELSE
                                        IF ("Questionnaire-Code4" = "Questionnaire-Code6") THEN
                                            ERROR(Text001, "Questionnaire-Code4")
                                        ELSE
                                            IF ("Questionnaire-Code4" = "Questionnaire-Code7") THEN
                                                ERROR(Text001, "Questionnaire-Code4")
                                            ELSE
                                                IF ("Questionnaire-Code4" = "Questionnaire-Code8") THEN
                                                    ERROR(Text001, "Questionnaire-Code4");
                    END;
                    "Questionnaire-Desc4" := ProfileQuestionHeader.Description
                END ELSE
                    "Questionnaire-Desc4" := '';
            end;
        }
        field(14; "Questionnaire-Code5"; Code[20])
        {
            Caption = 'Questionnaire-Code5';
            TableRelation = "Profile Questionnaire Header".Code;

            trigger OnValidate()
            begin
                IF ProfileQuestionHeader.GET("Questionnaire-Code5") THEN BEGIN
                    IF "Questionnaire-Code5" <> '' THEN BEGIN
                        IF ("Questionnaire-Code5" = "Questionnaire-Code1") THEN
                            ERROR(Text001, "Questionnaire-Code5")
                        ELSE
                            IF ("Questionnaire-Code5" = "Questionnaire-Code2") THEN
                                ERROR(Text001, "Questionnaire-Code5")
                            ELSE
                                IF ("Questionnaire-Code5" = "Questionnaire-Code3") THEN
                                    ERROR(Text001, "Questionnaire-Code5")
                                ELSE
                                    IF ("Questionnaire-Code5" = "Questionnaire-Code4") THEN
                                        ERROR(Text001, "Questionnaire-Code5")
                                    ELSE
                                        IF ("Questionnaire-Code5" = "Questionnaire-Code6") THEN
                                            ERROR(Text001, "Questionnaire-Code5")
                                        ELSE
                                            IF ("Questionnaire-Code5" = "Questionnaire-Code7") THEN
                                                ERROR(Text001, "Questionnaire-Code5")
                                            ELSE
                                                IF ("Questionnaire-Code5" = "Questionnaire-Code8") THEN
                                                    ERROR(Text001, "Questionnaire-Code5");
                    END;
                    "Questionnaire-Desc5" := ProfileQuestionHeader.Description;
                END ELSE
                    "Questionnaire-Desc5" := '';
            end;
        }
        field(15; "Questionnaire-Code6"; Code[20])
        {
            Caption = 'Questionnaire-Code6';
            TableRelation = "Profile Questionnaire Header".Code;

            trigger OnValidate()
            begin
                IF ProfileQuestionHeader.GET("Questionnaire-Code6") THEN BEGIN
                    IF "Questionnaire-Code6" <> '' THEN BEGIN
                        IF ("Questionnaire-Code6" = "Questionnaire-Code1") THEN
                            ERROR(Text001, "Questionnaire-Code6")
                        ELSE
                            IF ("Questionnaire-Code6" = "Questionnaire-Code2") THEN
                                ERROR(Text001, "Questionnaire-Code6")
                            ELSE
                                IF ("Questionnaire-Code6" = "Questionnaire-Code3") THEN
                                    ERROR(Text001, "Questionnaire-Code6")
                                ELSE
                                    IF ("Questionnaire-Code6" = "Questionnaire-Code4") THEN
                                        ERROR(Text001, "Questionnaire-Code6")
                                    ELSE
                                        IF ("Questionnaire-Code6" = "Questionnaire-Code5") THEN
                                            ERROR(Text001, "Questionnaire-Code6")
                                        ELSE
                                            IF ("Questionnaire-Code6" = "Questionnaire-Code7") THEN
                                                ERROR(Text001, "Questionnaire-Code6")
                                            ELSE
                                                IF ("Questionnaire-Code6" = "Questionnaire-Code8") THEN
                                                    ERROR(Text001, "Questionnaire-Code6");
                    END;
                    "Questionnaire-Desc6" := ProfileQuestionHeader.Description
                END ELSE
                    "Questionnaire-Desc6" := '';
            end;
        }
        field(16; "Questionnaire-Code7"; Code[20])
        {
            Caption = 'Questionnaire-Code7';
            TableRelation = "Profile Questionnaire Header".Code;

            trigger OnValidate()
            begin
                IF ProfileQuestionHeader.GET("Questionnaire-Code7") THEN BEGIN
                    IF "Questionnaire-Code7" <> '' THEN BEGIN
                        IF ("Questionnaire-Code7" = "Questionnaire-Code1") THEN
                            ERROR(Text001, "Questionnaire-Code7")
                        ELSE
                            IF ("Questionnaire-Code7" = "Questionnaire-Code2") THEN
                                ERROR(Text001, "Questionnaire-Code7")
                            ELSE
                                IF ("Questionnaire-Code7" = "Questionnaire-Code3") THEN
                                    ERROR(Text001, "Questionnaire-Code7")
                                ELSE
                                    IF ("Questionnaire-Code7" = "Questionnaire-Code4") THEN
                                        ERROR(Text001, "Questionnaire-Code7")
                                    ELSE
                                        IF ("Questionnaire-Code7" = "Questionnaire-Code5") THEN
                                            ERROR(Text001, "Questionnaire-Code7")
                                        ELSE
                                            IF ("Questionnaire-Code7" = "Questionnaire-Code6") THEN
                                                ERROR(Text001, "Questionnaire-Code7")
                                            ELSE
                                                IF ("Questionnaire-Code7" = "Questionnaire-Code8") THEN
                                                    ERROR(Text001, "Questionnaire-Code7");
                    END;
                    "Questionnaire-Desc7" := ProfileQuestionHeader.Description
                END ELSE
                    "Questionnaire-Desc7" := '';
            end;
        }
        field(17; "Questionnaire-Code8"; Code[20])
        {
            Caption = 'Questionnaire-Code8';
            TableRelation = "Profile Questionnaire Header".Code;

            trigger OnValidate()
            begin
                IF ProfileQuestionHeader.GET("Questionnaire-Code8") THEN BEGIN
                    IF "Questionnaire-Code8" <> '' THEN BEGIN
                        IF ("Questionnaire-Code8" = "Questionnaire-Code1") THEN
                            ERROR(Text001, "Questionnaire-Code8")
                        ELSE
                            IF ("Questionnaire-Code8" = "Questionnaire-Code2") THEN
                                ERROR(Text001, "Questionnaire-Code8")
                            ELSE
                                IF ("Questionnaire-Code8" = "Questionnaire-Code3") THEN
                                    ERROR(Text001, "Questionnaire-Code8")
                                ELSE
                                    IF ("Questionnaire-Code8" = "Questionnaire-Code4") THEN
                                        ERROR(Text001, "Questionnaire-Code8")
                                    ELSE
                                        IF ("Questionnaire-Code8" = "Questionnaire-Code5") THEN
                                            ERROR(Text001, "Questionnaire-Code8")
                                        ELSE
                                            IF ("Questionnaire-Code8" = "Questionnaire-Code6") THEN
                                                ERROR(Text001, "Questionnaire-Code8")
                                            ELSE
                                                IF ("Questionnaire-Code8" = "Questionnaire-Code7") THEN
                                                    ERROR(Text001, "Questionnaire-Code8");
                    END;
                    "Questionnaire-Desc8" := ProfileQuestionHeader.Description
                END ELSE
                    "Questionnaire-Desc8" := '';
            end;
        }
        field(18; "Questionnaire-Desc1"; Text[30])
        {
            Caption = 'Questionnaire-Desc1';
        }
        field(19; "Questionnaire-Desc2"; Text[30])
        {
            Caption = 'Questionnaire-Desc2';
        }
        field(20; "Questionnaire-Desc3"; Text[30])
        {
            Caption = 'Questionnaire-Desc3';
        }
        field(21; "Questionnaire-Desc4"; Text[30])
        {
            Caption = 'Questionnaire-Desc4';
        }
        field(22; "Questionnaire-Desc5"; Text[30])
        {
            Caption = 'Questionnaire-Desc5';
        }
        field(23; "Questionnaire-Desc6"; Text[30])
        {
            Caption = 'Questionnaire-Desc6';
        }
        field(24; "Questionnaire-Desc7"; Text[30])
        {
            Caption = 'Questionnaire-Desc7';
        }
        field(25; "Questionnaire-Desc8"; Text[30])
        {
            Caption = 'Questionnaire-Desc8';
        }
        field(26; "Same No. Series"; Boolean)
        {
        }
        field(27; "Facility No."; Code[10])
        {
            TableRelation = "No. Series";
        }
        field(28; "Event No."; Code[10])
        {
            TableRelation = "No. Series";
        }
        field(29; "Premise Group Caption"; Text[30])
        {
        }
        field(30; "Premise Sub Group Caption"; Text[30])
        {
        }
        field(31; "Default Source Code"; Code[10])
        {
            TableRelation = "Source Code";
        }
        field(32; "Commission Agent"; Code[10])
        {
            TableRelation = "No. Series".Code;
        }
        field(33; Insurance; Code[10])
        {
            TableRelation = "No. Series".Code;
        }
        field(50; "No. of Premises"; Integer)
        {
            CalcFormula = Count (Premise WHERE (Premise/Sub-Premise=FILTER(Premise)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(51;"No. of Sub Premises";Integer)
        {
            CalcFormula = Count(Premise WHERE (Premise/Sub-Premise=FILTER(Sub-Premise)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(60;"Vacant Premises";Integer)
        {
            BlankZero = true;
            CalcFormula = Count(Premise WHERE (No.=FIELD(Premise No. Filter),
                                               Premise Group=FIELD(Premise Group Filter),
                                               Premise Sub Group=FIELD(Premise Sub Group Filter),
                                               Floor No.=FIELD(Premise Floor Filter),
                                               Premise Status=FILTER(Vacant),
                                               Premise/Sub-Premise=FIELD(Premise Type Filter)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(61;"Booked Premises";Integer)
        {
            BlankZero = true;
            CalcFormula = Count(Premise WHERE (No.=FIELD(Premise No. Filter),
                                               Premise Group=FIELD(Premise Group Filter),
                                               Premise Sub Group=FIELD(Premise Sub Group Filter),
                                               Floor No.=FIELD(Premise Floor Filter),
                                               Premise Status=FILTER(Booked),
                                               Premise/Sub-Premise=FIELD(Premise Type Filter)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(62;"Sold Premises";Integer)
        {
            BlankZero = true;
            CalcFormula = Count(Premise WHERE (No.=FIELD(Premise No. Filter),
                                               Premise Group=FIELD(Premise Group Filter),
                                               Premise Sub Group=FIELD(Premise Sub Group Filter),
                                               Floor No.=FIELD(Premise Floor Filter),
                                               Premise Status=FILTER(Sold),
                                               Premise/Sub-Premise=FIELD(Premise Type Filter)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(63;"On Lease Premises";Integer)
        {
            BlankZero = true;
            CalcFormula = Count(Premise WHERE (No.=FIELD(Premise No. Filter),
                                               Premise Group=FIELD(Premise Group Filter),
                                               Premise Sub Group=FIELD(Premise Sub Group Filter),
                                               Floor No.=FIELD(Premise Floor Filter),
                                               Premise Status=FILTER(On Lease),
                                               Premise/Sub-Premise=FIELD(Premise Type Filter)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(64;"Premise Group Filter";Code[20])
        {
            FieldClass = FlowFilter;
        }
        field(65;"Premise Sub Group Filter";Code[20])
        {
            FieldClass = FlowFilter;
        }
        field(66;"Premise No. Filter";Code[20])
        {
            FieldClass = FlowFilter;
        }
        field(67;"Premise Type Filter";Option)
        {
            FieldClass = FlowFilter;
            OptionCaption = 'Premise,Sub-Premise';
            OptionMembers = Premise,"Sub-Premise";
        }
        field(68;"Premise Floor Filter";Code[20])
        {
            FieldClass = FlowFilter;
        }
        field(71;"Client Sales Amount";Decimal)
        {
            CalcFormula = Sum("Client Sales Transactions"."Net Amount (LCY)" WHERE (Client No.=FIELD(Client No. Filter),
                                                                                    Item Category Code=FIELD(Item Category Code Filter),
                                                                                    Product Group=FIELD(Product Group Filter),
                                                                                    Date=FIELD(Date Filter)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(72;"Client No. Filter";Code[20])
        {
            FieldClass = FlowFilter;
        }
        field(73;"Item Category Code Filter";Code[20])
        {
            FieldClass = FlowFilter;
        }
        field(74;"Product Group Filter";Code[20])
        {
            FieldClass = FlowFilter;
        }
        field(75;"Date Filter";Date)
        {
            FieldClass = FlowFilter;
        }
        field(76;"Client No.";Code[10])
        {
            TableRelation = "No. Series";
        }
        field(77;"Agreement Invoice Nos.";Code[10])
        {
            TableRelation = "No. Series";
        }
        field(78;"Agreement Cr. Memo Nos.";Code[10])
        {
            TableRelation = "No. Series";
        }
        field(79;"Print Receipt Mandatory";Boolean)
        {
        }
        field(80;"Revenue Sharing";Boolean)
        {
        }
        field(81;"Facility Group Caption";Text[20])
        {
        }
        field(82;"Facility Sub Group Caption";Text[20])
        {
        }
        field(83;"Mailing Group Caption";Text[20])
        {
        }
        field(84;"Business Relation Caption";Text[20])
        {
        }
        field(85;"Industry Group Caption";Text[20])
        {
        }
        field(86;"Contract A/C No. Caption";Text[20])
        {
        }
        field(87;"Consumer No. Caption";Text[20])
        {
        }
        field(88;"Issued By Authority Caption";Text[20])
        {
        }
        field(89;"Rounding Precision";Decimal)
        {
        }
        field(90;"Rounding Type";Option)
        {
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        field(91;"Meter No.";Text[30])
        {
        }
        field(50010;"VAT Bus. Posting Group";Code[10])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(50011;"VAT Prod. Posting Group";Code[10])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(50012;"Customer Posting Group";Code[10])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
        }
        field(50013;"Gen. Bus. Posting Group";Code[10])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(50014;"Gen. Prod. Posting Group";Code[10])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(50015;"Reason Code";Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
    }

    keys
    {
        key(Key1;"Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ProfileQuestionHeader: Record "Profile Questionnaire Header";
        Text001: Label 'Profile Questioniarre Code %1 is already selected.';
}

