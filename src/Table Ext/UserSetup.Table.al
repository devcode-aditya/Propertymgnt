table 91 "User Setup"
{
    // DP = changes made by DVS
    // DP6.01.02 HK 19SEP2013 : Added field "Allow Pre-closure"
    // Code          Date          Name        Description
    // APNT-HR1.0    12.11.13      Sangeeta    Added fields for HR & Payroll Customization.
    // APNT-RES1.0   24.02.14      Sangeeta    Added fields for Transfer Ship & Receive Restriction customization.
    // T003249       01.04.14      Tanweer     Added field as per the mail request from Sandeep Rana - Ticket No. 16996
    // APNT-HRU2.0   04.08.14      Ashish      Added field for HRU - Restore Purchase Order from Archive
    // T006180       17.03.15      Tanweer     Added fields (50500,50501) for Lease Management Customizations
    // T008201       08.10.15      Sujith      Added fields for lease management customization.
    // T033255       02.06.20      Saajid      Added field for the Reservation cancellation feature
    // T044145       13.07.22      Sujith      Added field for CRF_22_0859

    Caption = 'User Setup';
    DrillDownFormID = Form119;
    LookupFormID = Form119;

    fields
    {
        field(1; "User ID"; Code[20])
        {
            Caption = 'User ID';
            NotBlank = true;
            TableRelation = User;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                LoginMgt: Codeunit "418";
            begin
                LoginMgt.LookupUserID("User ID");
            end;

            trigger OnValidate()
            var
                LoginMgt: Codeunit "418";
            begin
                LoginMgt.ValidateUserID("User ID");
            end;
        }
        field(2; "Allow Posting From"; Date)
        {
            Caption = 'Allow Posting From';
        }
        field(3; "Allow Posting To"; Date)
        {
            Caption = 'Allow Posting To';
        }
        field(4; "Register Time"; Boolean)
        {
            Caption = 'Register Time';
        }
        field(10; "Salespers./Purch. Code"; Code[10])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = Salesperson/Purchaser.Code;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSetup: Record "91";
            begin
                IF "Salespers./Purch. Code" <> '' THEN BEGIN
                  UserSetup.SETCURRENTKEY("Salespers./Purch. Code");
                  UserSetup.SETRANGE("Salespers./Purch. Code","Salespers./Purch. Code");
                  IF UserSetup.FIND('-') THEN
                    ERROR(Text001,"Salespers./Purch. Code",UserSetup."User ID");
                END;
            end;
        }
        field(11;"Approver ID";Code[20])
        {
            Caption = 'Approver ID';
            TableRelation = "User Setup"."User ID";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(12;"Sales Amount Approval Limit";Integer)
        {
            BlankZero = true;
            Caption = 'Sales Amount Approval Limit';

            trigger OnValidate()
            begin
                IF "Unlimited Sales Approval" AND ("Sales Amount Approval Limit" <> 0) THEN
                  ERROR(Text003,FIELDCAPTION("Sales Amount Approval Limit"),FIELDCAPTION("Unlimited Sales Approval"));
                IF "Sales Amount Approval Limit" < 0 THEN
                  ERROR(Text005);
            end;
        }
        field(13;"Purchase Amount Approval Limit";Integer)
        {
            BlankZero = true;
            Caption = 'Purchase Amount Approval Limit';

            trigger OnValidate()
            begin
                IF "Unlimited Purchase Approval" AND ("Purchase Amount Approval Limit" <> 0) THEN
                  ERROR(Text003,FIELDCAPTION("Purchase Amount Approval Limit"),FIELDCAPTION("Unlimited Purchase Approval"));
                IF "Purchase Amount Approval Limit" < 0 THEN
                  ERROR(Text005);
            end;
        }
        field(14;"Unlimited Sales Approval";Boolean)
        {
            Caption = 'Unlimited Sales Approval';

            trigger OnValidate()
            begin
                IF "Unlimited Sales Approval" THEN
                  "Sales Amount Approval Limit" := 0;
            end;
        }
        field(15;"Unlimited Purchase Approval";Boolean)
        {
            Caption = 'Unlimited Purchase Approval';

            trigger OnValidate()
            begin
                IF "Unlimited Purchase Approval" THEN
                  "Purchase Amount Approval Limit" := 0;
            end;
        }
        field(16;Substitute;Code[20])
        {
            Caption = 'Substitute';
            TableRelation = "User Setup";
        }
        field(17;"E-Mail";Text[100])
        {
            Caption = 'E-Mail';
            ExtendedDatatype = EMail;
        }
        field(19;"Request Amount Approval Limit";Integer)
        {
            BlankZero = true;
            Caption = 'Request Amount Approval Limit';

            trigger OnValidate()
            begin
                IF "Unlimited Request Approval" AND ("Request Amount Approval Limit" <> 0) THEN
                  ERROR(Text003,FIELDCAPTION("Request Amount Approval Limit"),FIELDCAPTION("Unlimited Request Approval"));
                IF "Request Amount Approval Limit" < 0 THEN
                  ERROR(Text005);
            end;
        }
        field(20;"Unlimited Request Approval";Boolean)
        {
            Caption = 'Unlimited Request Approval';

            trigger OnValidate()
            begin
                IF "Unlimited Request Approval" THEN
                  "Request Amount Approval Limit" := 0;
            end;
        }
        field(5600;"Allow FA Posting From";Date)
        {
            Caption = 'Allow FA Posting From';
        }
        field(5601;"Allow FA Posting To";Date)
        {
            Caption = 'Allow FA Posting To';
        }
        field(5700;"Sales Resp. Ctr. Filter";Code[10])
        {
            Caption = 'Sales Resp. Ctr. Filter';
            TableRelation = "Responsibility Center".Code;
        }
        field(5701;"Purchase Resp. Ctr. Filter";Code[10])
        {
            Caption = 'Purchase Resp. Ctr. Filter';
            TableRelation = "Responsibility Center";
        }
        field(5900;"Service Resp. Ctr. Filter";Code[10])
        {
            Caption = 'Service Resp. Ctr. Filter';
            TableRelation = "Responsibility Center";
        }
        field(50000;"Allow Transfer Ship";Boolean)
        {
            Description = 'APNT-RES1.0';
        }
        field(50001;"Allow Transfer Reciept";Boolean)
        {
            Description = 'APNT-RES1.0';
        }
        field(50002;"Hide Item Cost";Boolean)
        {
            Description = 'APNT-RES1.0';
        }
        field(50003;"Hide Vendor No.";Boolean)
        {
            Description = 'APNT-RES1.0';
        }
        field(50004;"Retrieve Purchase Order";Boolean)
        {
            Description = 'APNT-HRU2.0';
        }
        field(50005;"Allow Sent Trans. Req. Reopen";Boolean)
        {
            Description = 'APNT-HRU2.0';
        }
        field(50010;"Reopen Allowed";Boolean)
        {
            Description = 'T008201';
        }
        field(50015;"Allow Reservation Cancellation";Boolean)
        {
            Description = 'APNT-33255';
        }
        field(50050;"Unlimited Journal Approval";Boolean)
        {
            Description = 'APNT-PV1.0';

            trigger OnValidate()
            begin
                IF "Unlimited Journal Approval" THEN
                  "Journal Approval Limit" := 0;
            end;
        }
        field(50051;"Journal Approval Limit";Integer)
        {
            BlankZero = true;
            Description = 'APNT-PV1.0';

            trigger OnValidate()
            begin
                IF "Unlimited Journal Approval" AND ("Journal Approval Limit" <> 0) THEN
                  ERROR(Text003,FIELDCAPTION("Journal Approval Limit"),FIELDCAPTION("Unlimited Journal Approval"));
                IF "Journal Approval Limit" < 0 THEN
                  ERROR(Text005);
            end;
        }
        field(50052;"Treasury User";Boolean)
        {
            Description = 'APNT-PV1.0';
        }
        field(50100;"WMS Super";Boolean)
        {
            Description = 'WMS1.0';
        }
        field(50500;"Sign Lease Agreement";Boolean)
        {
            Description = 'T006180';
        }
        field(50501;"Amend Lease Agreement";Boolean)
        {
            Description = 'T006180';
        }
        field(50600;"Allow Modify/Delete HHT Lines";Boolean)
        {
            Description = 'APNT-T032566';
        }
        field(50601;"Vendor Approver ID";Code[20])
        {
            Description = 'T044145';
            TableRelation = "User Setup"."User ID";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(50602;"Final Approver";Boolean)
        {
            Description = 'T044145';
        }
        field(60000;"Leave Encashment Approval";Boolean)
        {
            Description = 'APNT-HR1.0';
        }
        field(60001;"Full and Final Approval";Boolean)
        {
            Description = 'APNT-HR1.0';
        }
        field(60002;"Leave Approval";Boolean)
        {
            Description = 'APNT-HR1.0';
        }
        field(60003;"Employee No.";Code[20])
        {
            Description = 'APNT-HR1.0';
            TableRelation = Employee;
        }
        field(60004;"Reminder Notification Type";Text[30])
        {
            Description = 'APNT-HR1.0';
        }
        field(60005;"Receive Reminder Notification";Boolean)
        {
            Description = 'APNT-HR1.0';
        }
        field(60006;"Receive Passport Notification";Boolean)
        {
            Description = 'APNT-HR1.0';
        }
        field(60007;"Receive Visa Notification";Boolean)
        {
            Description = 'APNT-HR1.0';
        }
        field(60008;"Receive Health Notification";Boolean)
        {
            Description = 'APNT-HR1.0';
        }
        field(60009;"Receive Work Permit Not.";Boolean)
        {
            Caption = 'Receive Work Permit Notification';
            Description = 'APNT-HR1.0';
        }
        field(60010;"Receive Leave Approval Not.";Boolean)
        {
            Caption = 'Receive Leave Approval Notification';
            Description = 'APNT-HR1.0';
        }
        field(60011;"Receive Custody Notification";Boolean)
        {
            Caption = 'Receive Custody of Articles Notification';
            Description = 'APNT-HR1.0';
        }
        field(60012;"Receive Probation Notification";Boolean)
        {
            Caption = 'Receive Completion of Probation Notification';
            Description = 'APNT-HR1.0';
        }
        field(60013;"Half Day Leave Approval";Boolean)
        {
            Description = 'APNT-HR1.0';
        }
        field(60014;"Payroll User";Boolean)
        {
            Description = 'T003249';
        }
        field(33016800;"Agreement Amt. App. Limit";Integer)
        {
            BlankZero = true;
            Description = 'DP6.01.01';
        }
        field(33016801;"Unlimited Agreement Approval";Boolean)
        {
            Description = 'DP6.01.01';
        }
        field(33016802;"Work Order Amt. App. Limit";Integer)
        {
            BlankZero = true;
            Description = 'DP6.01.01';
        }
        field(33016803;"Unlimited Work Order Approval";Boolean)
        {
            Description = 'DP6.01.01';
        }
        field(33016804;"Edit Receipt Journal";Boolean)
        {
            Description = 'DP6.01.01';
        }
        field(33016805;"Approve Reciept Jnl";Boolean)
        {
            Description = 'DP6.01.01';
        }
        field(33016806;"Print Receipt Copy";Boolean)
        {
            Description = 'DP6.01.01';
        }
        field(33016807;"UnProcess Rcpt. Jnl.";Boolean)
        {
            Description = 'DP6.01.01';
        }
        field(33016808;"Allow Pre-Closure";Boolean)
        {
            Description = 'DP6.01.02';
        }
    }

    keys
    {
        key(Key1;"User ID")
        {
            Clustered = true;
        }
        key(Key2;"Salespers./Purch. Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'The %1 Salesperson/Purchaser code is already assigned to another User ID %2.';
        Text003: Label 'You cannot have both a %1 and %2. ';
        Text005: Label 'You cannot have approval limits less than zero.';
}

