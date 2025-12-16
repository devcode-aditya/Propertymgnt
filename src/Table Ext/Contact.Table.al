table 5050 Contact
{
    // LS = changes made by LS Retail
    // 
    // CODE      DATE      NAME        DESCRIPTION
    // APNT-1.0  10.01.11  Tanweer     Added fields
    // DP = changes made by DVS
    // T001634   23.10.13  Shameema    Added fields

    Caption = 'Contact';
    DataCaptionFields = "No.", Name;
    LookupFormID = Form5052;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                IF "No." <> xRec."No." THEN BEGIN
                    RMSetup.GET;
                    NoSeriesMgt.TestManual(RMSetup."Contact Nos.");
                    "No. Series" := '';
                END;
            end;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';

            trigger OnValidate()
            var
                ContBusRel: Record "5054";
                Cust: Record "18";
                Vend: Record "23";
            begin
                IF NOT (CurrFieldNo IN [FIELDNO("First Name"), FIELDNO("Middle Name"), FIELDNO(Surname)]) THEN
                    NameBreakdown;
                UpdateSearchName;

                IF Type = Type::Company THEN
                    "Company Name" := Name;

                IF Type = Type::Person THEN BEGIN
                    ContBusRel.RESET;
                    ContBusRel.SETCURRENTKEY("Link to Table", "Contact No.");
                    ContBusRel.SETRANGE("Link to Table", ContBusRel."Link to Table"::Customer);
                    ContBusRel.SETRANGE("Contact No.", "Company No.");
                    IF ContBusRel.FIND('-') THEN
                        IF Cust.GET(ContBusRel."No.") THEN
                            IF Cust."Primary Contact No." = "No." THEN BEGIN
                                Cust.Contact := Name;
                                Cust.MODIFY;
                            END;

                    ContBusRel.SETRANGE("Link to Table", ContBusRel."Link to Table"::Vendor);
                    IF ContBusRel.FIND('-') THEN
                        IF Vend.GET(ContBusRel."No.") THEN
                            IF Vend."Primary Contact No." = "No." THEN BEGIN
                                Vend.Contact := Name;
                                Vend.MODIFY;
                            END;
                END;
            end;
        }
        field(3; "Search Name"; Code[50])
        {
            Caption = 'Search Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[50])
        {
            Caption = 'Address';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(7; City; Text[30])
        {
            Caption = 'City';

            trigger OnLookup()
            begin
                PostCode.LookUpCity(City, "Post Code", TRUE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code");
            end;
        }
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(10; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        field(15; "Territory Code"; Code[10])
        {
            Caption = 'Territory Code';
            TableRelation = Territory;
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(29; "Salesperson Code"; Code[10])
        {
            Caption = 'Salesperson Code';
            TableRelation = Salesperson/Purchaser;
        }
        field(35;"Country/Region Code";Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = Country/Region;
        }
        field(38;Comment;Boolean)
        {
            CalcFormula = Exist("Rlshp. Mgt. Comment Line" WHERE (Table Name=CONST(Contact),
                                                                  No.=FIELD(No.),
                                                                  Sub No.=CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(54;"Last Date Modified";Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(84;"Fax No.";Text[30])
        {
            Caption = 'Fax No.';
        }
        field(85;"Telex Answer Back";Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(86;"VAT Registration No.";Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            var
                VATRegNoFormat: Record "381";
            begin
                VATRegNoFormat.Test("VAT Registration No.","Country/Region Code","No.",DATABASE::Contact);
            end;
        }
        field(89;Picture;BLOB)
        {
            Caption = 'Picture';
            SubType = Bitmap;
        }
        field(91;"Post Code";Code[20])
        {
            Caption = 'Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookUpPostCode(City,"Post Code",TRUE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City,"Post Code");
            end;
        }
        field(92;County;Text[30])
        {
            Caption = 'County';
        }
        field(102;"E-Mail";Text[80])
        {
            Caption = 'E-Mail';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            begin
                IF ("Search E-Mail" = UPPERCASE(xRec."E-Mail")) OR ("Search E-Mail" = '') THEN
                  "Search E-Mail" := "E-Mail";
            end;
        }
        field(103;"Home Page";Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(107;"No. Series";Code[10])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(5050;Type;Option)
        {
            Caption = 'Type';
            OptionCaption = 'Company,Person';
            OptionMembers = Company,Person;

            trigger OnValidate()
            begin
                IF CurrFieldNo <> 0 THEN BEGIN
                  TypeChange;
                  MODIFY;
                END;
            end;
        }
        field(5051;"Company No.";Code[20])
        {
            Caption = 'Company No.';
            TableRelation = Contact WHERE (Type=CONST(Company));

            trigger OnValidate()
            var
                Opp: Record "5092";
                OppEntry: Record "5093";
                Todo: Record "5080";
                InteractLogEntry: Record "5065";
                SegLine: Record "5077";
                SalesHeader: Record "36";
                ChangeLogMgt: Codeunit "423";
                RecRef: RecordRef;
                xRecRef: RecordRef;
            begin
                IF "Company No." = xRec."Company No." THEN
                  EXIT;

                xRecRef.GETTABLE(Rec);

                TESTFIELD(Type,Type::Person);

                SegLine.SETCURRENTKEY("Contact No.");
                SegLine.SETRANGE("Contact No.","No.");
                IF SegLine.FIND('-') THEN
                  ERROR(Text012,FIELDCAPTION("Company No."));

                IF Cont.GET("Company No.") THEN
                  InheritCompanyToPersonData(Cont,xRec."Company No." = '')
                ELSE
                  CLEAR("Company Name");

                IF Cont.GET("No.") THEN BEGIN
                  IF xRec."Company No." <> '' THEN BEGIN
                    Opp.SETCURRENTKEY("Contact Company No.","Contact No.");
                    Opp.SETRANGE("Contact Company No.",xRec."Company No.");
                    Opp.SETRANGE("Contact No.","No.");
                    Opp.MODIFYALL("Contact No.",xRec."Company No.");
                    OppEntry.SETCURRENTKEY("Contact Company No.","Contact No.");
                    OppEntry.SETRANGE("Contact Company No.",xRec."Company No.");
                    OppEntry.SETRANGE("Contact No.","No.");
                    OppEntry.MODIFYALL("Contact No.",xRec."Company No.");
                    Todo.SETCURRENTKEY("Contact Company No.","Contact No.");
                    Todo.SETRANGE("Contact Company No.",xRec."Company No.");
                    Todo.SETRANGE("Contact No.","No.");
                    Todo.MODIFYALL("Contact No.",xRec."Company No.");
                    InteractLogEntry.SETCURRENTKEY("Contact Company No.","Contact No.");
                    InteractLogEntry.SETRANGE("Contact Company No.",xRec."Company No.");
                    InteractLogEntry.SETRANGE("Contact No.","No.");
                    InteractLogEntry.MODIFYALL("Contact No.",xRec."Company No.");
                    ContBusRel.RESET;
                    ContBusRel.SETCURRENTKEY("Link to Table","No.");
                    ContBusRel.SETRANGE("Link to Table",ContBusRel."Link to Table"::Customer);
                    ContBusRel.SETRANGE("Contact No.",xRec."Company No.");
                    SalesHeader.SETCURRENTKEY("Sell-to Customer No.","External Document No.");
                    SalesHeader.SETRANGE("Sell-to Contact No.","No.");
                    IF ContBusRel.FIND('-') THEN
                      SalesHeader.SETRANGE("Sell-to Customer No.",ContBusRel."No.")
                    ELSE
                      SalesHeader.SETRANGE("Sell-to Customer No.",'');
                    IF SalesHeader.FIND('-') THEN
                      REPEAT
                        SalesHeader."Sell-to Contact No." := xRec."Company No.";
                        IF SalesHeader."Sell-to Contact No." = SalesHeader."Bill-to Contact No." THEN
                          SalesHeader."Bill-to Contact No." := xRec."Company No.";
                        SalesHeader.MODIFY;
                      UNTIL SalesHeader.NEXT = 0;
                    SalesHeader.RESET;
                    SalesHeader.SETCURRENTKEY("Bill-to Contact No.");
                    SalesHeader.SETRANGE("Bill-to Contact No.","No.");
                    SalesHeader.MODIFYALL("Bill-to Contact No.",xRec."Company No.");
                  END ELSE BEGIN
                    Opp.SETCURRENTKEY("Contact Company No.","Contact No.");
                    Opp.SETRANGE("Contact Company No.",'');
                    Opp.SETRANGE("Contact No.","No.");
                    Opp.MODIFYALL("Contact Company No.","Company No.");
                    OppEntry.SETCURRENTKEY("Contact Company No.","Contact No.");
                    OppEntry.SETRANGE("Contact Company No.",'');
                    OppEntry.SETRANGE("Contact No.","No.");
                    OppEntry.MODIFYALL("Contact Company No.","Company No.");
                    Todo.SETCURRENTKEY("Contact Company No.","Contact No.");
                    Todo.SETRANGE("Contact Company No.",'');
                    Todo.SETRANGE("Contact No.","No.");
                    Todo.MODIFYALL("Contact Company No.","Company No.");
                    InteractLogEntry.SETCURRENTKEY("Contact Company No.","Contact No.");
                    InteractLogEntry.SETRANGE("Contact Company No.",'');
                    InteractLogEntry.SETRANGE("Contact No.","No.");
                    InteractLogEntry.MODIFYALL("Contact Company No.","Company No.");
                  END;
                  IF CurrFieldNo <> 0 THEN BEGIN
                    MODIFY;
                    RecRef.GETTABLE(Rec);
                    ChangeLogMgt.LogModification(RecRef,xRecRef);
                  END;
                END;
            end;
        }
        field(5052;"Company Name";Text[50])
        {
            Caption = 'Company Name';
            Editable = false;
        }
        field(5053;"Lookup Contact No.";Code[20])
        {
            Caption = 'Lookup Contact No.';
            Editable = false;
            TableRelation = Contact;

            trigger OnValidate()
            begin
                IF Type = Type::Company THEN
                  "Lookup Contact No." := ''
                ELSE
                  "Lookup Contact No." := "No.";
            end;
        }
        field(5054;"First Name";Text[30])
        {
            Caption = 'First Name';

            trigger OnValidate()
            begin
                VALIDATE(Name,CalculatedName);
            end;
        }
        field(5055;"Middle Name";Text[30])
        {
            Caption = 'Middle Name';

            trigger OnValidate()
            begin
                VALIDATE(Name,CalculatedName);
            end;
        }
        field(5056;Surname;Text[30])
        {
            Caption = 'Surname';

            trigger OnValidate()
            begin
                VALIDATE(Name,CalculatedName);
            end;
        }
        field(5058;"Job Title";Text[30])
        {
            Caption = 'Job Title';
        }
        field(5059;Initials;Text[30])
        {
            Caption = 'Initials';
        }
        field(5060;"Extension No.";Text[30])
        {
            Caption = 'Extension No.';
        }
        field(5061;"Mobile Phone No.";Text[30])
        {
            Caption = 'Mobile Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(5062;Pager;Text[30])
        {
            Caption = 'Pager';
        }
        field(5063;"Organizational Level Code";Code[10])
        {
            Caption = 'Organizational Level Code';
            TableRelation = "Organizational Level";
        }
        field(5064;"Exclude from Segment";Boolean)
        {
            Caption = 'Exclude from Segment';
        }
        field(5065;"Date Filter";Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5066;"Next To-do Date";Date)
        {
            CalcFormula = Min(To-do.Date WHERE (Contact Company No.=FIELD(Company No.),
                                                Contact No.=FIELD(FILTER(Lookup Contact No.)),
                                                Closed=CONST(No),
                                                System To-do Type=CONST(Contact Attendee)));
            Caption = 'Next To-do Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5067;"Last Date Attempted";Date)
        {
            CalcFormula = Max("Interaction Log Entry".Date WHERE (Contact Company No.=FIELD(Company No.),
                                                                  Contact No.=FIELD(FILTER(Lookup Contact No.)),
                                                                  Initiated By=CONST(Us),
                                                                  Postponed=CONST(No)));
            Caption = 'Last Date Attempted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5068;"Date of Last Interaction";Date)
        {
            CalcFormula = Max("Interaction Log Entry".Date WHERE (Contact Company No.=FIELD(Company No.),
                                                                  Contact No.=FIELD(FILTER(Lookup Contact No.)),
                                                                  Attempt Failed=CONST(No),
                                                                  Postponed=CONST(No)));
            Caption = 'Date of Last Interaction';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5069;"No. of Job Responsibilities";Integer)
        {
            CalcFormula = Count("Contact Job Responsibility" WHERE (Contact No.=FIELD(No.)));
            Caption = 'No. of Job Responsibilities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5070;"No. of Industry Groups";Integer)
        {
            CalcFormula = Count("Contact Industry Group" WHERE (Contact No.=FIELD(Company No.)));
            Caption = 'No. of Industry Groups';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5071;"No. of Business Relations";Integer)
        {
            CalcFormula = Count("Contact Business Relation" WHERE (Contact No.=FIELD(Company No.)));
            Caption = 'No. of Business Relations';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5072;"No. of Mailing Groups";Integer)
        {
            CalcFormula = Count("Contact Mailing Group" WHERE (Contact No.=FIELD(No.)));
            Caption = 'No. of Mailing Groups';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5073;"External ID";Code[20])
        {
            Caption = 'External ID';
        }
        field(5074;"No. of Interactions";Integer)
        {
            CalcFormula = Count("Interaction Log Entry" WHERE (Contact Company No.=FIELD(Company No.),
                                                               Canceled=CONST(No),
                                                               Contact No.=FIELD(FILTER(Lookup Contact No.)),
                                                               Date=FIELD(Date Filter),
                                                               Postponed=CONST(No)));
            Caption = 'No. of Interactions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5076;"Cost (LCY)";Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Interaction Log Entry"."Cost (LCY)" WHERE (Contact Company No.=FIELD(Company No.),
                                                                          Canceled=CONST(No),
                                                                          Contact No.=FIELD(FILTER(Lookup Contact No.)),
                                                                          Date=FIELD(Date Filter),
                                                                          Postponed=CONST(No)));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5077;"Duration (Min.)";Decimal)
        {
            CalcFormula = Sum("Interaction Log Entry"."Duration (Min.)" WHERE (Contact Company No.=FIELD(Company No.),
                                                                               Canceled=CONST(No),
                                                                               Contact No.=FIELD(FILTER(Lookup Contact No.)),
                                                                               Date=FIELD(Date Filter),
                                                                               Postponed=CONST(No)));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0:0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5078;"No. of Opportunities";Integer)
        {
            CalcFormula = Count("Opportunity Entry" WHERE (Active=CONST(Yes),
                                                           Contact Company No.=FIELD(Company No.),
                                                           Estimated Close Date=FIELD(Date Filter),
                                                           Contact No.=FIELD(FILTER(Lookup Contact No.)),
                                                           Action Taken=FIELD(Action Taken Filter)));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5079;"Estimated Value (LCY)";Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Opportunity Entry"."Estimated Value (LCY)" WHERE (Active=CONST(Yes),
                                                                                 Contact Company No.=FIELD(Company No.),
                                                                                 Estimated Close Date=FIELD(Date Filter),
                                                                                 Contact No.=FIELD(FILTER(Lookup Contact No.)),
                                                                                 Action Taken=FIELD(Action Taken Filter)));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5080;"Calcd. Current Value (LCY)";Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Opportunity Entry"."Calcd. Current Value (LCY)" WHERE (Active=CONST(Yes),
                                                                                      Contact Company No.=FIELD(Company No.),
                                                                                      Estimated Close Date=FIELD(Date Filter),
                                                                                      Contact No.=FIELD(FILTER(Lookup Contact No.)),
                                                                                      Action Taken=FIELD(Action Taken Filter)));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5082;"Opportunity Entry Exists";Boolean)
        {
            CalcFormula = Exist("Opportunity Entry" WHERE (Active=CONST(Yes),
                                                           Contact Company No.=FIELD(Company No.),
                                                           Contact No.=FIELD(FILTER(Lookup Contact No.)),
                                                           Sales Cycle Code=FIELD(Sales Cycle Filter),
                                                           Sales Cycle Stage=FIELD(Sales Cycle Stage Filter),
                                                           Salesperson Code=FIELD(Salesperson Filter),
                                                           Campaign No.=FIELD(Campaign Filter),
                                                           Action Taken=FIELD(Action Taken Filter),
                                                           Estimated Value (LCY)=FIELD(Estimated Value Filter),
                                                           Calcd. Current Value (LCY)=FIELD(Calcd. Current Value Filter),
                                                           Completed %=FIELD(Completed % Filter),
                                                           Chances of Success %=FIELD(Chances of Success % Filter),
                                                           Probability %=FIELD(Probability % Filter),
                                                           Estimated Close Date=FIELD(Date Filter),
                                                           Close Opportunity Code=FIELD(Close Opportunity Filter)));
            Caption = 'Opportunity Entry Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5083;"To-do Entry Exists";Boolean)
        {
            CalcFormula = Exist(To-do WHERE (Contact Company No.=FIELD(Company No.),
                                             Contact No.=FIELD(FILTER(Lookup Contact No.)),
                                             Team Code=FIELD(Team Filter),
                                             Salesperson Code=FIELD(Salesperson Filter),
                                             Campaign No.=FIELD(Campaign Filter),
                                             Date=FIELD(Date Filter),
                                             Status=FIELD(To-do Status Filter),
                                             Priority=FIELD(Priority Filter),
                                             Closed=FIELD(To-do Closed Filter)));
            Caption = 'To-do Entry Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5084;"Salesperson Filter";Code[10])
        {
            Caption = 'Salesperson Filter';
            FieldClass = FlowFilter;
            TableRelation = Salesperson/Purchaser;
        }
        field(5085;"Campaign Filter";Code[20])
        {
            Caption = 'Campaign Filter';
            FieldClass = FlowFilter;
            TableRelation = Campaign;
        }
        field(5087;"Action Taken Filter";Option)
        {
            Caption = 'Action Taken Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,Next,Previous,Updated,Jumped,Won,Lost';
            OptionMembers = " ",Next,Previous,Updated,Jumped,Won,Lost;
        }
        field(5088;"Sales Cycle Filter";Code[10])
        {
            Caption = 'Sales Cycle Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle";
        }
        field(5089;"Sales Cycle Stage Filter";Integer)
        {
            Caption = 'Sales Cycle Stage Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle Stage".Stage WHERE (Sales Cycle Code=FIELD(Sales Cycle Filter));
        }
        field(5090;"Probability % Filter";Decimal)
        {
            Caption = 'Probability % Filter';
            DecimalPlaces = 1:1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5091;"Completed % Filter";Decimal)
        {
            Caption = 'Completed % Filter';
            DecimalPlaces = 1:1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5092;"Estimated Value Filter";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Estimated Value Filter';
            FieldClass = FlowFilter;
        }
        field(5093;"Calcd. Current Value Filter";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Calcd. Current Value Filter';
            FieldClass = FlowFilter;
        }
        field(5094;"Chances of Success % Filter";Decimal)
        {
            Caption = 'Chances of Success % Filter';
            DecimalPlaces = 0:0;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5095;"To-do Status Filter";Option)
        {
            Caption = 'To-do Status Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Not Started,In Progress,Completed,Waiting,Postponed';
            OptionMembers = "Not Started","In Progress",Completed,Waiting,Postponed;
        }
        field(5096;"To-do Closed Filter";Boolean)
        {
            Caption = 'To-do Closed Filter';
            FieldClass = FlowFilter;
        }
        field(5097;"Priority Filter";Option)
        {
            Caption = 'Priority Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(5098;"Team Filter";Code[10])
        {
            Caption = 'Team Filter';
            FieldClass = FlowFilter;
            TableRelation = Team;
        }
        field(5099;"Close Opportunity Filter";Code[10])
        {
            Caption = 'Close Opportunity Filter';
            FieldClass = FlowFilter;
            TableRelation = "Close Opportunity Code";
        }
        field(5100;"Correspondence Type";Option)
        {
            Caption = 'Correspondence Type';
            OptionCaption = ' ,Hard Copy,E-Mail,Fax';
            OptionMembers = " ","Hard Copy","E-Mail",Fax;
        }
        field(5101;"Salutation Code";Code[10])
        {
            Caption = 'Salutation Code';
            TableRelation = Salutation;
        }
        field(5102;"Search E-Mail";Code[80])
        {
            Caption = 'Search E-Mail';
        }
        field(5104;"Last Time Modified";Time)
        {
            Caption = 'Last Time Modified';
        }
        field(5105;"E-Mail 2";Text[80])
        {
            Caption = 'E-Mail 2';
            ExtendedDatatype = EMail;
        }
        field(50000;Nationality;Text[30])
        {
            Description = 'APNT-1.0';
        }
        field(50001;"Event Code";Code[10])
        {
            Description = 'APNT-1.0';
            TableRelation = Event;

            trigger OnValidate()
            begin
                //APNT-1.0
                CALCFIELDS("Event Name");
                //APNT-1.0
            end;
        }
        field(50002;"Event Name";Text[30])
        {
            CalcFormula = Lookup(Event.Description WHERE (Code=FIELD(Event Code)));
            Description = 'APNT-1.0';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50003;Date;Date)
        {
            Description = 'APNT-1.0';
        }
        field(50052;"Contact Net Sales";Decimal)
        {
            CalcFormula = -Sum("Transaction Header"."Net Amount" WHERE (Sell-to Contact No.=FIELD(No.),
                                                                        Date=FIELD(Date Filter)));
            Description = '0028,T001634';
            FieldClass = FlowField;
        }
        field(50053;"Contact Total Discount";Decimal)
        {
            CalcFormula = Sum("Transaction Header"."Total Discount" WHERE (Sell-to Contact No.=FIELD(No.),
                                                                           Date=FIELD(Date Filter)));
            Description = '0028,T001634';
            FieldClass = FlowField;
        }
        field(50054;"Contact Line Discount";Decimal)
        {
            CalcFormula = Sum("Transaction Header"."Discount Amount" WHERE (Sell-to Contact No.=FIELD(No.),
                                                                            Date=FIELD(Date Filter)));
            Description = '0028,T001634';
            FieldClass = FlowField;
        }
        field(10000700;"Point Status";Decimal)
        {
            CalcFormula = Sum("Loyalty Points Transactions".Points WHERE (Contact No.=FIELD(No.),
                                                                          Loyalty Scheme=FIELD(Loyalty Scheme Filter),
                                                                          Expiration Date=FIELD(Date Filter)));
            Caption = 'Point Status';
            DecimalPlaces = 0:0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(10000701;"Issued Points";Decimal)
        {
            CalcFormula = Sum("Loyalty Points Transactions".Points WHERE (Contact No.=FIELD(No.),
                                                                          Loyalty Scheme=FIELD(Loyalty Scheme Filter),
                                                                          Date Of Issue=FIELD(Date Filter),
                                                                          Entry Type=CONST(Sale)));
            Caption = 'Issued Points';
            DecimalPlaces = 0:0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(10000702;"Used Points";Decimal)
        {
            CalcFormula = Sum("Loyalty Points Transactions".Points WHERE (Contact No.=FIELD(No.),
                                                                          Loyalty Scheme=FIELD(Loyalty Scheme Filter),
                                                                          Date Of Issue=FIELD(Date Filter),
                                                                          Entry Type=CONST(Payment)));
            Caption = 'Used Points';
            DecimalPlaces = 0:0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(10000703;"Loyalty Scheme Filter";Code[20])
        {
            Caption = 'Loyalty Scheme Filter';
            FieldClass = FlowFilter;
            TableRelation = "Loyalty Schemes".Code;
        }
        field(10001200;"Next Order Selection";Option)
        {
            Caption = 'Next Order Selection';
            OptionCaption = 'No Choice,Delivery Home,Delivery Work,Delivery Other,Takeout';
            OptionMembers = "No Choice","Delivery Home","Delivery Work","Delivery Other",Takeout;
        }
        field(10001201;"Next Order Restaurant";Code[20])
        {
            Caption = 'Next Order Restaurant';
        }
        field(10001202;"Next Order Date";Date)
        {
            Caption = 'Next Order Date';
        }
        field(10001203;"Next Order Time";Time)
        {
            Caption = 'Next Order Time';
        }
        field(10001204;"Next Delivery Tender";Option)
        {
            Caption = 'Next Delivery Tender';
            OptionCaption = 'None,Cash,Card,Purchase';
            OptionMembers = "None",Cash,Card,Purchase;
        }
        field(10001205;"Recall Order";Code[20])
        {
            Caption = 'Recall Order';
        }
        field(10001206;"Next Order Rest. Temporary";Boolean)
        {
            Caption = 'Next Order Rest. Temporary';
        }
        field(10001207;"Date Created";Date)
        {
            Caption = 'Date Created';
        }
        field(10001208;"No. of Open Orders";Integer)
        {
            CalcFormula = Count("Delivery Order" WHERE (Phone No.=FIELD(No.)));
            Caption = 'No. of Open Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10001209;"No. of Posted Orders";Integer)
        {
            CalcFormula = Count("Posted Delivery Order" WHERE (Phone No.=FIELD(No.)));
            Caption = 'No. of Posted Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33016801;"Client Segment";Code[20])
        {
            Description = 'DP6.01.01';
            TableRelation = "Client Segment";
        }
        field(33016820;Premise;Code[20])
        {
            Description = 'DP6.01.01';
            TableRelation = Premise;
        }
    }

    keys
    {
        key(Key1;"No.")
        {
            Clustered = true;
        }
        key(Key2;"Search Name")
        {
        }
        key(Key3;"Company Name","Company No.",Type,Name)
        {
        }
        key(Key4;"Company No.")
        {
        }
        key(Key5;"Territory Code")
        {
        }
        key(Key6;"Salesperson Code")
        {
        }
        key(Key7;"VAT Registration No.")
        {
        }
        key(Key8;"Search E-Mail")
        {
        }
        key(Key9;Name)
        {
        }
        key(Key10;City)
        {
        }
        key(Key11;"Post Code")
        {
        }
        key(Key12;"Phone No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;"No.",Name,Type,City,"Post Code","Phone No.")
        {
        }
    }

    trigger OnDelete()
    var
        Todo: Record "5080";
        SegLine: Record "5077";
        ContIndustGrp: Record "5058";
        ContactWebSource: Record "5060";
        ContJobResp: Record "5067";
        ContMailingGrp: Record "5056";
        ContProfileAnswer: Record "5089";
        RMCommentLine: Record "5061";
        ContAltAddr: Record "5051";
        ContAltAddrDateRange: Record "5052";
        InteractLogEntry: Record "5065";
        Opp: Record "5092";
        CampaignTargetGrMgt: Codeunit "7030";
        DelContAddr: Record "10001219";
    begin
        Todo.SETCURRENTKEY("Contact Company No.","Contact No.",Closed,Date);
        Todo.SETRANGE("Contact Company No.","Company No.");
        Todo.SETRANGE("Contact No.","No.");
        Todo.SETRANGE(Closed,FALSE);
        IF Todo.FIND('-') THEN
          ERROR(Text000,TABLECAPTION,"No.");

        SegLine.SETCURRENTKEY("Contact No.");
        SegLine.SETRANGE("Contact No.","No.");
        IF SegLine.FIND('-') THEN
          ERROR(Text001,TABLECAPTION,"No.");

        Opp.SETCURRENTKEY("Contact Company No.","Contact No.");
        Opp.SETRANGE("Contact Company No.","Company No.");
        Opp.SETRANGE("Contact No.","No.");
        Opp.SETRANGE(Status,Opp.Status::"Not Started",Opp.Status::"In Progress");
        IF Opp.FIND('-') THEN
          ERROR(Text002,TABLECAPTION,"No.");

        CASE Type OF
          Type::Company: BEGIN
            ContBusRel.SETRANGE("Contact No.","No.");
            ContBusRel.DELETEALL;
            ContIndustGrp.SETRANGE("Contact No.","No.");
            ContIndustGrp.DELETEALL;
            ContactWebSource.SETRANGE("Contact No.","No.");
            ContactWebSource.DELETEALL;
            DuplMgt.RemoveContIndex(Rec,FALSE);
            InteractLogEntry.SETCURRENTKEY("Contact Company No.");
            InteractLogEntry.SETRANGE("Contact Company No.", "No.");
            IF InteractLogEntry.FIND('-') THEN
              REPEAT
                CampaignTargetGrMgt.DeleteContfromTargetGr(InteractLogEntry);
                CLEAR(InteractLogEntry."Contact Company No.");
                CLEAR(InteractLogEntry."Contact No.");
                InteractLogEntry.MODIFY;
              UNTIL InteractLogEntry.NEXT = 0;

            Cont.RESET;
            Cont.SETCURRENTKEY("Company No.");
            Cont.SETRANGE("Company No.","No.");
            Cont.SETRANGE(Type,Type::Person);
            IF Cont.FIND('-') THEN
              REPEAT
                RecRef.GETTABLE(Cont);
                Cont.DELETE(TRUE);
                ChangeLogMgt.LogDeletion(RecRef);
              UNTIL Cont.NEXT = 0;

            Opp.RESET;
            Opp.SETCURRENTKEY("Contact Company No.","Contact No.");
            Opp.SETRANGE("Contact Company No.","Company No.");
            Opp.SETRANGE("Contact No.","No.");
            IF Opp.FIND('-') THEN
              REPEAT
                CLEAR(Opp."Contact No.");
                CLEAR(Opp."Contact Company No.");
                Opp.MODIFY;
              UNTIL Opp.NEXT = 0;

            Todo.RESET;
            Todo.SETCURRENTKEY("Contact Company No.");
            Todo.SETRANGE("Contact Company No.","Company No.");
            IF Todo.FIND('-') THEN
              REPEAT
                CLEAR(Todo."Contact No.");
                CLEAR(Todo."Contact Company No.");
                Todo.MODIFY;
              UNTIL Todo.NEXT = 0;
            SearchWordDetail.RESET;
            SearchWordDetail.SETCURRENTKEY("No.","Sub No.","Table Name");
            SearchWordDetail.SETRANGE("No.","No.");
            SearchWordDetail.SETFILTER(
              "Table Name",'%1|%2|%3',
              SearchWordDetail."Table Name"::"Interaction Log Entry",
              SearchWordDetail."Table Name"::"To-do",
              SearchWordDetail."Table Name"::Opportunity);
            IF SearchWordDetail.FIND('-') THEN BEGIN
              REPEAT
                SearchWordDetail.RENAME(
                  SearchWordDetail."Search Word Entry No.",
                  '',
                  SearchWordDetail."Sub No.",
                  SearchWordDetail."Table Name",
                  SearchWordDetail."Field No.",
                  SearchWordDetail."Word Position");
              UNTIL SearchWordDetail.NEXT = 0;
            END;
          END;

          Type::Person: BEGIN
            ContJobResp.SETRANGE("Contact No.", "No.");
            ContJobResp.DELETEALL;

            InteractLogEntry.SETCURRENTKEY("Contact Company No.","Contact No.");
            InteractLogEntry.SETRANGE("Contact Company No.","Company No.");
            InteractLogEntry.SETRANGE("Contact No.","No.");
            InteractLogEntry.MODIFYALL("Contact No.","Company No.");

            Opp.RESET;
            Opp.SETCURRENTKEY("Contact Company No.","Contact No.");
            Opp.SETRANGE("Contact Company No.","Company No.");
            Opp.SETRANGE("Contact No.","No.");
            Opp.MODIFYALL("Contact No.","Company No.");

            Todo.RESET;
            Todo.SETCURRENTKEY("Contact Company No.","Contact No.");
            Todo.SETRANGE("Contact Company No.","Company No.");
            Todo.SETRANGE("Contact No.","No.");
            Todo.MODIFYALL("Contact No.","Company No.");
            SearchWordDetail.RESET;
            SearchWordDetail.SETCURRENTKEY("No.","Sub No.","Table Name");
            SearchWordDetail.SETRANGE("No.","No.");
            SearchWordDetail.SETFILTER(
              "Table Name",'%1|%2|%3',
              SearchWordDetail."Table Name"::"Interaction Log Entry",
              SearchWordDetail."Table Name"::"To-do",
              SearchWordDetail."Table Name"::Opportunity);
            IF SearchWordDetail.FIND('-') THEN BEGIN
              REPEAT
                SearchWordDetail.RENAME(
                  SearchWordDetail."Search Word Entry No.",
                  "Company No.",
                  SearchWordDetail."Sub No.",
                  SearchWordDetail."Table Name",
                  SearchWordDetail."Field No.",
                  SearchWordDetail."Word Position");
              UNTIL SearchWordDetail.NEXT = 0;
            END;
          END;
        END;

        ContMailingGrp.SETRANGE("Contact No.","No.");
        ContMailingGrp.DELETEALL;

        ContProfileAnswer.SETRANGE("Contact No.","No.");
        ContProfileAnswer.DELETEALL;

        RMCommentLine.SETRANGE("Table Name",RMCommentLine."Table Name"::Contact);
        RMCommentLine.SETRANGE("No.","No.");
        RMCommentLine.SETRANGE("Sub No.",0);
        IF RMCommentLine.FIND('-') THEN
          REPEAT
            SearchManagement.DeleteCommentDetails(
              RMCommentLine."No.",
              RMCommentLine."Line No.");
          UNTIL RMCommentLine.NEXT = 0;
        RMCommentLine.DELETEALL;

        ContAltAddr.SETRANGE("Contact No.","No.");
        ContAltAddr.DELETEALL;

        ContAltAddrDateRange.SETRANGE("Contact No.","No.");
        ContAltAddrDateRange.DELETEALL;
        SearchManagement.DeleteContactDetails("No.");

        //LS -
        CreateAction(2);
        DelContAddr.SETRANGE(DelContAddr."Phone No.","No.");
        DelContAddr.DELETEALL(TRUE);
        //LS +
    end;

    trigger OnInsert()
    begin
        RMSetup.GET;

        IF "No." = '' THEN BEGIN
          RMSetup.TESTFIELD("Contact Nos.");
          NoSeriesMgt.InitSeries(RMSetup."Contact Nos.",xRec."No. Series",0D,"No.","No. Series");
        END;

        IF NOT SkipDefaults THEN BEGIN
          IF "Salesperson Code" = '' THEN
            "Salesperson Code" := RMSetup."Default Salesperson Code";
          IF "Territory Code" = '' THEN
            "Territory Code" := RMSetup."Default Territory Code";
          IF "Country/Region Code" = '' THEN
            "Country/Region Code" := RMSetup."Default Country/Region Code";
          IF "Language Code" = '' THEN
            "Language Code" := RMSetup."Default Language Code";
          IF "Correspondence Type" = "Correspondence Type"::" " THEN
            "Correspondence Type" := RMSetup."Default Correspondence Type";
          IF "Salutation Code" = '' THEN
            IF Type = Type::Company THEN
              "Salutation Code" := RMSetup."Def. Company Salutation Code"
            ELSE
              "Salutation Code" := RMSetup."Default Person Salutation Code";
        END;

        TypeChange;


        "Last Date Modified" := TODAY;
        "Last Time Modified" := TIME;
        "Date Created" := TODAY;  //LS
        CreateAction(0);  //LS
    end;

    trigger OnModify()
    begin
        OnModify(xRec);
        CreateAction(1);  //LS
    end;

    trigger OnRename()
    var
        SearchWordDetail2: Record "5118";
    begin
        VALIDATE("Lookup Contact No.");


        SearchWordDetail.RESET;
        SearchWordDetail.SETRANGE("No.",xRec."No.");
        IF SearchWordDetail.FINDSET(TRUE,TRUE) THEN
          REPEAT
            SearchWordDetail2 := SearchWordDetail;
            SearchWordDetail2.RENAME(
              SearchWordDetail."Search Word Entry No.",
              "No.",
              SearchWordDetail."Sub No.",
              SearchWordDetail."Table Name",
              SearchWordDetail."Field No.",
              SearchWordDetail."Word Position");
          UNTIL SearchWordDetail.NEXT = 0;
        CreateAction(3);  //LS
    end;

    var
        Text000: Label 'You cannot delete the %2 record of the %1 because there are one or more to-dos open.';
        Text001: Label 'You cannot delete the %2 record of the %1 because the contact is assigned one or more unlogged segments.';
        Text002: Label 'You cannot delete the %2 record of the %1 because one or more opportunities are in not started or progress.';
        Text003: Label '%1 cannot be changed because one or more interaction log entries are linked to the contact.';
        Text005: Label '%1 cannot be changed because one or more to-dos are linked to the contact.';
        Text006: Label '%1 cannot be changed because one or more opportunities are linked to the contact.';
        Text007: Label '%1 cannot be changed because there are one or more related people linked to the contact.';
        Text009: Label 'The %2 record of the %1 has been created.';
        Text010: Label 'The %2 record of the %1 is not linked with any other table.';
        RMSetup: Record "5079";
        Cont: Record "5050";
        ContBusRel: Record "5054";
        SearchWordDetail: Record "5118";
        PostCode: Record "225";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        DuplMgt: Codeunit "5060";
        NoSeriesMgt: Codeunit "396";
        ChangeLogMgt: Codeunit "423";
        UpdateCustVendBank: Codeunit "5055";
        SearchManagement: Codeunit "5067";
        CampaignMgt: Codeunit "7030";
        ContChanged: Boolean;
        SkipDefaults: Boolean;
        Text012: Label 'You cannot change %1 because one or more unlogged segments are assigned to the contact.';
        Text019: Label 'The %2 record of the %1 already has the %3 with %4 %5.';
        Text020: Label 'Do you want to create a contact %1 %2 as a customer using a customer template?';
        Text021: Label 'You have to set up formal and informal salutation formulas in %1  language for the %2 contact.';
        HideValidationDialog: Boolean;
        Text022: Label 'The creation of the customer has been aborted.';
        Text029: Label 'The total length of first name, middle name and surname is %1 character(s)longer than the maximum length allowed for the Name field.';
        Text032: Label 'The length of %1 is %2 character(s)longer than the maximum length allowed for the %1 field.';
        Text033: Label 'Before you can use Online Map, you must fill in the Online Map Setup window.\See Setting Up Online Map in Help.';
 
    procedure OnModify(xRec: Record "5050")
    var
        OldCont: Record "5050";
    begin
        "Last Date Modified" := TODAY;
        "Last Time Modified" := TIME;
        IF Name <> xRec.Name THEN
          SearchManagement.ParseField(
            "No.","No.",Name,SearchWordDetail."Table Name"::Contact,FIELDNO(Name));

        IF  "Company Name" <> xRec."Company Name" THEN
          SearchManagement.ParseField(
            "No.","No.","Company Name",SearchWordDetail."Table Name"::Contact,FIELDNO("Company Name"));

        IF  "Search Name" <> xRec."Search Name" THEN
          SearchManagement.ParseField(
            "No.","No.","Search Name",SearchWordDetail."Table Name"::Contact,FIELDNO("Search Name"));

        IF  "Name 2" <> xRec."Name 2" THEN
          SearchManagement.ParseField(
            "No.","No.","Name 2",SearchWordDetail."Table Name"::Contact,FIELDNO("Name 2"));

        IF  Address <> xRec.Address THEN
          SearchManagement.ParseField(
            "No.","No.",Address,SearchWordDetail."Table Name"::Contact,FIELDNO(Address));

        IF  "Address 2" <> xRec."Address 2" THEN
          SearchManagement.ParseField(
            "No.","No.","Address 2",SearchWordDetail."Table Name"::Contact,FIELDNO("Address 2"));

        IF  City <> xRec.City THEN
          SearchManagement.ParseField(
            "No.","No.",City,SearchWordDetail."Table Name"::Contact,FIELDNO(City));

        IF  "Phone No." <> xRec."Phone No." THEN
          SearchManagement.ParseField(
            "No.","No.","Phone No.",SearchWordDetail."Table Name"::Contact,FIELDNO("Phone No."));

        IF  "Telex No." <> xRec."Telex No." THEN
          SearchManagement.ParseField(
            "No.","No.","Telex No.",SearchWordDetail."Table Name"::Contact,FIELDNO("Telex No."));

        IF  "Fax No." <> xRec."Fax No." THEN
          SearchManagement.ParseField(
            "No.","No.","Fax No.",SearchWordDetail."Table Name"::Contact,FIELDNO("Fax No."));

        IF  Pager <> xRec.Pager THEN
          SearchManagement.ParseField(
            "No.","No.",Pager,SearchWordDetail."Table Name"::Contact,FIELDNO(Pager));

        IF  "Telex Answer Back" <> xRec."Telex Answer Back" THEN
          SearchManagement.ParseField(
            "No.","No.","Telex Answer Back",SearchWordDetail."Table Name"::Contact,FIELDNO("Telex Answer Back"));

        IF  "VAT Registration No." <> xRec."VAT Registration No." THEN
          SearchManagement.ParseField(
            "No.","No.","VAT Registration No.",SearchWordDetail."Table Name"::Contact,FIELDNO("VAT Registration No."));

        IF  "Post Code" <> xRec."Post Code" THEN
          SearchManagement.ParseField(
            "No.","No.","Post Code",SearchWordDetail."Table Name"::Contact,FIELDNO("Post Code"));

        IF  County <> xRec.County THEN
          SearchManagement.ParseField(
            "No.","No.",County,SearchWordDetail."Table Name"::Contact,FIELDNO(County));

        IF  "E-Mail" <> xRec."E-Mail" THEN
          SearchManagement.ParseField(
            "No.","No.","E-Mail",SearchWordDetail."Table Name"::Contact,FIELDNO("E-Mail"));

        IF  "Home Page" <> xRec."Home Page" THEN
          SearchManagement.ParseField(
            "No.","No.","Home Page",SearchWordDetail."Table Name"::Contact,FIELDNO("Home Page"));

        IF  "Mobile Phone No." <> xRec."Mobile Phone No." THEN
          SearchManagement.ParseField(
            "No.","No.","Mobile Phone No.",SearchWordDetail."Table Name"::Contact,FIELDNO("Mobile Phone No."));

        IF Type = Type::Company THEN BEGIN
          IF (Name <> xRec.Name) OR
             ("Search Name" <> xRec."Search Name") OR
             ("Name 2" <> xRec."Name 2") OR
             (Address <> xRec.Address) OR
             ("Address 2" <> xRec."Address 2") OR
             (City <> xRec.City) OR
             ("Phone No." <> xRec."Phone No.") OR
             ("Telex No." <> xRec."Telex No.") OR
             ("Territory Code" <> xRec."Territory Code") OR
             ("Currency Code" <> xRec."Currency Code") OR
             ("Language Code" <> xRec."Language Code") OR
             ("Salesperson Code" <> xRec."Salesperson Code") OR
             ("Country/Region Code" <> xRec."Country/Region Code") OR
             ("Fax No." <> xRec."Fax No.") OR
             ("Telex Answer Back" <> xRec."Telex Answer Back") OR
             ("VAT Registration No." <> xRec."VAT Registration No.") OR
             ("Post Code" <> xRec."Post Code") OR
             (County <> xRec.County) OR
             ("E-Mail" <> xRec."E-Mail") OR
             ("Home Page" <> xRec."Home Page")
          THEN
            UpdateCustVendBank.RUN(Rec);

          RMSetup.GET;
          Cont.RESET;
          Cont.SETCURRENTKEY("Company No.");
          Cont.SETRANGE("Company No.","No.");
          Cont.SETRANGE(Type,Type::Person);
          IF Cont.FIND('-') THEN
            REPEAT
              ContChanged := FALSE;
              OldCont := Cont;
              IF Name <> xRec.Name THEN BEGIN
                Cont."Company Name" := Name;
                ContChanged := TRUE;
              END;
              IF RMSetup."Inherit Salesperson Code" AND
                 (xRec."Salesperson Code" <> "Salesperson Code") AND
                 (xRec."Salesperson Code" = Cont."Salesperson Code")
              THEN BEGIN
                Cont."Salesperson Code" := "Salesperson Code";
                ContChanged := TRUE;
              END;
              IF RMSetup."Inherit Territory Code" AND
                 (xRec."Territory Code" <> "Territory Code") AND
                 (xRec."Territory Code" = Cont."Territory Code")
              THEN BEGIN
                Cont."Territory Code" := "Territory Code";
                ContChanged := TRUE;
              END;
              IF RMSetup."Inherit Country/Region Code" AND
                 (xRec."Country/Region Code" <> "Country/Region Code") AND
                 (xRec."Country/Region Code" = Cont."Country/Region Code")
              THEN BEGIN
                Cont."Country/Region Code" := "Country/Region Code";
                ContChanged := TRUE;
              END;
              IF RMSetup."Inherit Language Code" AND
                 (xRec."Language Code" <> "Language Code") AND
                 (xRec."Language Code" = Cont."Language Code")
              THEN BEGIN
                Cont."Language Code" := "Language Code";
                ContChanged := TRUE;
              END;
              IF RMSetup."Inherit Address Details" THEN BEGIN
                IF xRec.IdenticalAddress(Cont) THEN BEGIN
                  IF xRec.Address <> Address THEN BEGIN
                    Cont.Address := Address;
                    ContChanged := TRUE;
                  END;
                  IF xRec."Address 2" <> "Address 2" THEN BEGIN
                    Cont."Address 2" := "Address 2";
                    ContChanged := TRUE;
                  END;
                  IF xRec."Post Code" <> "Post Code" THEN BEGIN
                    Cont."Post Code" := "Post Code";
                    ContChanged := TRUE;
                  END;
                  IF xRec.City <> City THEN BEGIN
                    Cont.City := City;
                    ContChanged := TRUE;
                  END;
                END;
              END;
              IF RMSetup."Inherit Communication Details" THEN BEGIN
                IF (xRec."Phone No." <> "Phone No.") AND (xRec."Phone No." = Cont."Phone No.") THEN BEGIN
                  Cont."Phone No." := "Phone No.";
                  ContChanged := TRUE;
                END;
                IF (xRec."Telex No." <> "Telex No.") AND (xRec."Telex No." = Cont."Telex No.") THEN BEGIN
                  Cont."Telex No." := "Telex No.";
                  ContChanged := TRUE;
                END;
                IF (xRec."Fax No." <> "Fax No.") AND (xRec."Fax No." = Cont."Fax No.") THEN BEGIN
                  Cont."Fax No." := "Fax No.";
                  ContChanged := TRUE;
                END;
                IF (xRec."Telex Answer Back" <> "Telex Answer Back") AND (xRec."Telex Answer Back" = Cont."Telex Answer Back") THEN BEGIN
                  Cont."Telex Answer Back" := "Telex Answer Back";
                  ContChanged := TRUE;
                END;
                IF (xRec."E-Mail" <> "E-Mail") AND (xRec."E-Mail" = Cont."E-Mail") THEN BEGIN
                  Cont.VALIDATE("E-Mail","E-Mail");
                  ContChanged := TRUE;
                END;
                IF (xRec."Home Page" <> "Home Page") AND (xRec."Home Page" = Cont."Home Page") THEN BEGIN
                  Cont."Home Page" := "Home Page";
                  ContChanged := TRUE;
                END;
                IF (xRec."Extension No." <> "Extension No.") AND (xRec."Extension No." = Cont."Extension No.") THEN BEGIN
                  Cont."Extension No." := "Extension No.";
                  ContChanged := TRUE;
                END;
                IF (xRec."Mobile Phone No." <> "Mobile Phone No.") AND (xRec."Mobile Phone No." = Cont."Mobile Phone No.") THEN BEGIN
                  Cont."Mobile Phone No." := "Mobile Phone No.";
                  ContChanged := TRUE;
                END;
                IF (xRec.Pager <> Pager) AND (xRec.Pager = Cont.Pager) THEN BEGIN
                  Cont.Pager := Pager;
                  ContChanged := TRUE;
                END;
              END;
              IF ContChanged THEN BEGIN
                Cont.OnModify(OldCont);
                Cont.MODIFY;
                xRecRef.GETTABLE(OldCont);
                RecRef.GETTABLE(Cont);
                ChangeLogMgt.LogModification(RecRef,xRecRef);
              END;
            UNTIL Cont.NEXT = 0;

          IF (Name <> xRec.Name) OR
             ("Name 2" <> xRec."Name 2") OR
             (Address <> xRec.Address) OR
             ("Address 2" <> xRec."Address 2") OR
             (City <> xRec.City) OR
             ("Post Code" <> xRec."Post Code") OR
             ("VAT Registration No." <> xRec."VAT Registration No.") OR
             ("Phone No." <> xRec."Phone No.")
          THEN
            CheckDupl;
        END;
    end;
 
    procedure TypeChange()
    var
        InteractLogEntry: Record "5065";
        Opp: Record "5092";
        Todo: Record "5080";
        CampaignTargetGrMgt: Codeunit "7030";
    begin
        RMSetup.GET;

        InteractLogEntry.LOCKTABLE;
        Todo.LOCKTABLE;
        Opp.LOCKTABLE;
        Cont.LOCKTABLE;
        InteractLogEntry.SETCURRENTKEY("Contact Company No.","Contact No.");
        InteractLogEntry.SETRANGE("Contact Company No.","Company No.");
        InteractLogEntry.SETRANGE("Contact No.","No.");
        IF InteractLogEntry.FIND('-') THEN
          ERROR(Text003,FIELDCAPTION(Type));
        Todo.SETCURRENTKEY("Contact Company No.","Contact No.");
        Todo.SETRANGE("Contact Company No.","Company No.");
        Todo.SETRANGE("Contact No.","No.");
        IF Todo.FIND('-') THEN
          ERROR(Text005,FIELDCAPTION(Type));
        Opp.SETCURRENTKEY("Contact Company No.","Contact No.");
        Opp.SETRANGE("Contact Company No.","Company No.");
        Opp.SETRANGE("Contact No.","No.");
        IF Opp.FIND('-') THEN
          ERROR(Text006,FIELDCAPTION(Type));

        CASE Type OF
          Type::Company:
            BEGIN
              TESTFIELD("Organizational Level Code",'');
              TESTFIELD("No. of Job Responsibilities",0);
              "First Name" := '';
              "Middle Name" := '';
              Surname := '';
              "Job Title" := '';
              "Company No." := "No.";
              "Company Name" := Name;
              SearchManagement.ParseField(
                "No.","No.","Company Name",
                SearchWordDetail."Table Name"::Contact,
                FIELDNO("Company Name"));
              "Salutation Code" := RMSetup."Def. Company Salutation Code";
            END;
          Type::Person:
            BEGIN
              CampaignTargetGrMgt.DeleteContfromTargetGr(InteractLogEntry);
              Cont.RESET;
              Cont.SETCURRENTKEY("Company No.");
              Cont.SETRANGE("Company No.","No.");
              Cont.SETRANGE(Type,Type::Person);
              IF Cont.FIND('-') THEN
                ERROR(Text007,FIELDCAPTION(Type));
              TESTFIELD("No. of Business Relations",0);
              TESTFIELD("No. of Industry Groups",0);
              TESTFIELD("Currency Code",'');
              TESTFIELD("VAT Registration No.",'');
              IF "Company No." = "No." THEN BEGIN
                "Company No." := '';
                "Company Name" := '';
                SearchManagement.DeletePrevDetails(
                  "No.","No.",
                  SearchWordDetail."Table Name"::Contact,
                  FIELDNO("Company Name"));
                "Salutation Code" := RMSetup."Default Person Salutation Code";
                NameBreakdown;
              END;
            END;
        END;
        VALIDATE("Lookup Contact No.");

        IF Cont.GET("No.") THEN BEGIN
          IF Type = Type::Company THEN
            CheckDupl
          ELSE
            DuplMgt.RemoveContIndex(Rec,FALSE);
        END;
    end;
 
    procedure AssistEdit(OldCont: Record "5050"): Boolean
    begin
        WITH Cont DO BEGIN
          Cont := Rec;
          RMSetup.GET;
          RMSetup.TESTFIELD("Contact Nos.");
          IF NoSeriesMgt.SelectSeries(RMSetup."Contact Nos.",OldCont."No. Series","No. Series") THEN BEGIN
            RMSetup.GET;
            RMSetup.TESTFIELD("Contact Nos.");
            NoSeriesMgt.SetSeries("No.");
            Rec := Cont;
            EXIT(TRUE);
          END;
        END;
    end;
 
    procedure CreateCustomer(CustomerTemplate: Code[10])
    var
        Cust: Record "18";
        ContComp: Record "5050";
        CustTemplate: Record "5105";
        DefaultDim: Record "352";
        DefaultDim2: Record "352";
    begin
        TESTFIELD("Company No.");
        RMSetup.GET;
        RMSetup.TESTFIELD("Bus. Rel. Code for Customers");

        ContBusRel.RESET;
        ContBusRel.SETRANGE("Contact No.","No.");
        ContBusRel.SETRANGE("Link to Table",ContBusRel."Link to Table"::Customer);
        IF ContBusRel.FIND('-') THEN
          ERROR(
            Text019,
            TABLECAPTION,"No.",ContBusRel.TABLECAPTION,ContBusRel."Link to Table",ContBusRel."No.")
        ELSE
          IF CustomerTemplate <> '' THEN
            CustTemplate.GET(CustomerTemplate);

        CLEAR(Cust);
        Cust.SetInsertFromContact(TRUE);
        Cust.INSERT(TRUE);
        Cust.SetInsertFromContact(FALSE);

        IF Type = Type::Company THEN
          ContComp := Rec
        ELSE
          ContComp.GET("Company No.");

        ContBusRel."Contact No." := ContComp."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Customers";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::Customer;
        ContBusRel."No." := Cust."No.";
        ContBusRel.INSERT(TRUE);

        UpdateCustVendBank.UpdateCustomer(ContComp,ContBusRel);

        Cust.GET(ContBusRel."No.");
        Cust.VALIDATE(Name,"Company Name");
        Cust.MODIFY;

        IF CustTemplate.Code <> '' THEN BEGIN
          Cust."Territory Code" := "Territory Code";
          Cust."Currency Code" := ContComp."Currency Code";
          Cust."Country/Region Code" := "Country/Region Code";
          Cust."Customer Posting Group" := CustTemplate."Customer Posting Group";
          Cust."Customer Price Group" := CustTemplate."Customer Price Group";
          Cust."Invoice Disc. Code" := CustTemplate."Invoice Disc. Code";
          Cust."Customer Disc. Group" := CustTemplate."Customer Disc. Group";
          Cust."Allow Line Disc." := CustTemplate."Allow Line Disc.";
          Cust."Gen. Bus. Posting Group" := CustTemplate."Gen. Bus. Posting Group";
          Cust."VAT Bus. Posting Group" := CustTemplate."VAT Bus. Posting Group";
          Cust."Payment Terms Code" := CustTemplate."Payment Terms Code";
          Cust."Payment Method Code" := CustTemplate."Payment Method Code";
          Cust."Shipment Method Code" := CustTemplate."Shipment Method Code";
          Cust.MODIFY;

          DefaultDim.SETRANGE("Table ID",DATABASE::"Customer Template");
          DefaultDim.SETRANGE("No.",CustTemplate.Code);
          IF DefaultDim.FIND('-') THEN
            REPEAT
              CLEAR(DefaultDim2);
              DefaultDim2.INIT;
              DefaultDim2.VALIDATE("Table ID",DATABASE::Customer);
              DefaultDim2."No." := Cust."No.";
              DefaultDim2.VALIDATE("Dimension Code",DefaultDim."Dimension Code");
              DefaultDim2.VALIDATE("Dimension Value Code",DefaultDim."Dimension Value Code");
              DefaultDim2."Value Posting" := DefaultDim."Value Posting";
              DefaultDim2.INSERT(TRUE);
            UNTIL DefaultDim.NEXT = 0;
        END;

        UpdateQuotes(Cust);
        CampaignMgt.ConverttoCustomer(Rec,Cust);
        MESSAGE(Text009,Cust.TABLECAPTION,Cust."No.");
    end;
 
    procedure CreateVendor()
    var
        Vend: Record "23";
        ContComp: Record "5050";
    begin
        TESTFIELD("Company No.");
        RMSetup.GET;
        RMSetup.TESTFIELD("Bus. Rel. Code for Vendors");

        CLEAR(Vend);
        Vend.SetInsertFromContact(TRUE);
        Vend.INSERT(TRUE);
        Vend.SetInsertFromContact(FALSE);

        IF Type = Type::Company THEN
          ContComp := Rec
        ELSE
          ContComp.GET("Company No.");

        ContBusRel."Contact No." := ContComp."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Vendors";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::Vendor;
        ContBusRel."No." := Vend."No.";
        ContBusRel.INSERT(TRUE);

        UpdateCustVendBank.UpdateVendor(ContComp,ContBusRel);

        MESSAGE(Text009,Vend.TABLECAPTION,Vend."No.");
    end;
 
    procedure CreateBankAccount()
    var
        BankAcc: Record "270";
        ContComp: Record "5050";
    begin
        TESTFIELD("Company No.");
        RMSetup.GET;
        RMSetup.TESTFIELD("Bus. Rel. Code for Bank Accs.");

        CLEAR(BankAcc);
        BankAcc.SetInsertFromContact(TRUE);
        BankAcc.INSERT(TRUE);
        BankAcc.SetInsertFromContact(FALSE);

        IF Type = Type::Company THEN
          ContComp := Rec
        ELSE
          ContComp.GET("Company No.");

        ContBusRel."Contact No." := ContComp."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Bank Accs.";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::"Bank Account";
        ContBusRel."No." := BankAcc."No.";
        ContBusRel.INSERT(TRUE);

        UpdateCustVendBank.UpdateBankAccount(ContComp,ContBusRel);

        MESSAGE(Text009,BankAcc.TABLECAPTION,BankAcc."No.");
    end;
 
    procedure CreateCustomerLink()
    var
        Cust: Record "18";
        ContBusRel: Record "5054";
    begin
        TESTFIELD("Company No.");
        RMSetup.GET;
        RMSetup.TESTFIELD("Bus. Rel. Code for Customers");
        CreateLink(
          FORM::"Customer Link",
          RMSetup."Bus. Rel. Code for Customers",
          ContBusRel."Link to Table"::Customer);

        ContBusRel.SETCURRENTKEY("Link to Table","No.");
        ContBusRel.SETRANGE("Link to Table",ContBusRel."Link to Table"::Customer);
        ContBusRel.SETRANGE("Contact No.","Company No.");
        IF ContBusRel.FIND('-') THEN
          IF Cust.GET(ContBusRel."No.") THEN
            UpdateQuotes(Cust);
    end;
 
    procedure CreateVendorLink()
    begin
        TESTFIELD("Company No.");
        RMSetup.GET;
        RMSetup.TESTFIELD("Bus. Rel. Code for Vendors");
        CreateLink(
          FORM::"Vendor Link",
          RMSetup."Bus. Rel. Code for Vendors",
          ContBusRel."Link to Table"::Vendor);
    end;
 
    procedure CreateBankAccountLink()
    begin
        TESTFIELD("Company No.");
        RMSetup.GET;
        RMSetup.TESTFIELD("Bus. Rel. Code for Bank Accs.");
        CreateLink(
          FORM::"Bank Account Link",
          RMSetup."Bus. Rel. Code for Bank Accs.",
          ContBusRel."Link to Table"::"Bank Account");
    end;
 
    procedure CreateLink(CreateForm: Integer;BusRelCode: Code[10];"Table": Option Customer,Vendor,"Bank Account")
    var
        TempContBusRel: Record "5054" temporary;
    begin
        TempContBusRel."Contact No." := "Company No.";
        TempContBusRel."Business Relation Code" := BusRelCode;
        TempContBusRel."Link to Table" := Table;
                                              TempContBusRel.INSERT;
                                              FORM.RUNMODAL(CreateForm,TempContBusRel);
                                              TempContBusRel.DELETEALL;
    end;
 
    procedure CreateInteraction()
    var
        SegmentLine: Record "5077" temporary;
    begin
        SegmentLine.CreateInteractionFromContact(Rec);
    end;
 
    procedure ShowCustVendBank()
    var
        ContBusRel: Record "5054";
        FormSelected: Boolean;
        Cust: Record "18";
        Vend: Record "23";
        BankAcc: Record "270";
    begin
        FormSelected := TRUE;

        ContBusRel.RESET;
        ContBusRel.SETRANGE("Contact No.","Company No.");
        ContBusRel.SETFILTER("No.",'<>''''');

        CASE ContBusRel.COUNT OF
          0: ERROR(Text010,TABLECAPTION,"No.");
          1: ContBusRel.FIND('-');
          ELSE
            FormSelected := FORM.RUNMODAL(FORM::"Contact Business Relations",ContBusRel) = ACTION::LookupOK;
        END;

        IF FormSelected THEN BEGIN
          CASE ContBusRel."Link to Table" OF
            ContBusRel."Link to Table"::Customer: BEGIN
              Cust.GET(ContBusRel."No.");
              FORM.RUN(FORM::"Customer Card",Cust);
            END;
            ContBusRel."Link to Table"::Vendor: BEGIN
              Vend.GET(ContBusRel."No.");
              FORM.RUN(FORM::"Vendor Card",Vend);
            END;
            ContBusRel."Link to Table"::"Bank Account": BEGIN
              BankAcc.GET(ContBusRel."No.");
              FORM.RUN(FORM::"Bank Account Card",BankAcc);
            END;
          END;
        END;
    end;
 
    procedure NameBreakdown()
    var
        NamePart: array [30] of Text[250];
        TempName: Text[250];
        FirstName250: Text[250];
        i: Integer;
        NoOfParts: Integer;
    begin
        IF Type = Type::Company THEN
          EXIT;

        TempName := Name;
        WHILE STRPOS(TempName,' ') > 0 DO BEGIN
          IF STRPOS(TempName,' ') > 1 THEN BEGIN
            i := i + 1;
            NamePart[i] := COPYSTR(TempName,1,STRPOS(TempName,' ') - 1);
          END;
          TempName := COPYSTR(TempName,STRPOS(TempName,' ') + 1);
        END;
        i := i + 1;
        NamePart[i] := TempName;
        NoOfParts := i;

        "First Name" := '';
        "Middle Name" := '';
        Surname := '';
        FOR i := 1 TO NoOfParts DO BEGIN
          IF (i = NoOfParts) AND (NoOfParts > 1) THEN BEGIN
            IF STRLEN(NamePart[i]) > MAXSTRLEN(Surname) THEN
              ERROR(Text032,FIELDCAPTION(Surname),STRLEN(NamePart[i]) - MAXSTRLEN(Surname));
            Surname := NamePart[i]
          END ELSE
            IF (i = NoOfParts - 1) AND (NoOfParts > 2) THEN BEGIN
              IF STRLEN(NamePart[i]) > MAXSTRLEN("Middle Name") THEN
                ERROR(Text032,FIELDCAPTION("Middle Name"),STRLEN(NamePart[i]) - MAXSTRLEN("Middle Name"));
              "Middle Name" := NamePart[i]
            END ELSE BEGIN
              FirstName250 := DELCHR("First Name" + ' ' + NamePart[i],'<',' ');
              IF STRLEN(FirstName250) > MAXSTRLEN("First Name") THEN
                ERROR(Text032,FIELDCAPTION("First Name"),STRLEN(FirstName250) - MAXSTRLEN("First Name"));
              "First Name" := FirstName250;
            END;
        END;
    end;
 
    procedure SetSkipDefault(Defaults: Boolean)
    begin
        SkipDefaults := NOT Defaults;
    end;
 
    procedure IdenticalAddress(var Cont: Record "5050"): Boolean
    begin
        EXIT(
          (Address = Cont.Address) AND
          ("Address 2" = Cont."Address 2") AND
          ("Post Code" = Cont."Post Code") AND
          (City = Cont.City))
    end;
 
    procedure ActiveAltAddress(ActiveDate: Date): Code[10]
    var
        ContAltAddrDateRange: Record "5052";
    begin
        ContAltAddrDateRange.SETCURRENTKEY("Contact No.","Starting Date");
        ContAltAddrDateRange.SETRANGE("Contact No.","No.");
        ContAltAddrDateRange.SETRANGE("Starting Date",0D,ActiveDate);
        ContAltAddrDateRange.SETFILTER("Ending Date",'>=%1|%2',ActiveDate,0D);
        IF ContAltAddrDateRange.FIND('+') THEN
          EXIT(ContAltAddrDateRange."Contact Alt. Address Code")
        ELSE
          EXIT('');
    end;
 
    procedure CalculatedName() NewName: Text[250]
    var
        NewName250: Text[250];
    begin
        IF "First Name" <> '' THEN
          NewName250 := "First Name";
        IF "Middle Name" <> '' THEN
          NewName250 := NewName250 + ' ' + "Middle Name";
        IF Surname <> '' THEN
          NewName250 := NewName250 + ' ' + Surname;

        NewName250 := DELCHR(NewName250,'<',' ');

        IF STRLEN(NewName250) > MAXSTRLEN(Name) THEN
          ERROR(Text029,STRLEN(NewName250) - MAXSTRLEN(Name));

        NewName := NewName250;
    end;
 
    procedure UpdateSearchName()
    begin
        IF ("Search Name" = UPPERCASE(xRec.Name)) OR ("Search Name" = '') THEN
          "Search Name" := Name;
    end;
 
    procedure AddText(Text: Text[249]): Text[250]
    begin
        IF Text <> '' THEN
          EXIT(Text + ' ');
    end;
 
    procedure CheckDupl()
    begin
        IF RMSetup."Maintain Dupl. Search Strings" THEN
          DuplMgt.MakeContIndex(Rec);
        IF GUIALLOWED THEN
          IF DuplMgt.DuplicateExist(Rec) THEN BEGIN
            MODIFY;
            COMMIT;
            DuplMgt.LaunchDuplicateForm(Rec);
          END;
    end;
 
    procedure FindCustomerTemplate() FindCustTemplate: Code[10]
    var
        CustTemplate: Record "5105";
        ContCompany: Record "5050";
    begin
        CustTemplate.RESET;
        CustTemplate.SETRANGE("Territory Code","Territory Code");
        CustTemplate.SETRANGE("Country/Region Code","Country/Region Code");
        IF ContCompany.GET("Company No.") THEN
          CustTemplate.SETRANGE("Currency Code",ContCompany."Currency Code");

        IF CustTemplate.COUNT = 1 THEN BEGIN
          CustTemplate.FIND('-');
          EXIT(CustTemplate.Code);
        END;
    end;
 
    procedure ChooseCustomerTemplate() ChooseCustTemplate: Code[10]
    var
        CustTemplate: Record "5105";
    begin
        ContBusRel.RESET;
        ContBusRel.SETRANGE("Contact No.","No.");
        ContBusRel.SETRANGE("Link to Table",ContBusRel."Link to Table"::Customer);
        IF ContBusRel.FIND('-') THEN
          ERROR(
            Text019,
            TABLECAPTION,"No.",ContBusRel.TABLECAPTION,ContBusRel."Link to Table",ContBusRel."No.")
        ELSE
          IF CONFIRM(Text020,TRUE,"No.",Name) THEN
            IF FORM.RUNMODAL(0,CustTemplate) = ACTION::LookupOK THEN
              EXIT(CustTemplate.Code)
            ELSE
              ERROR(Text022);
    end;
 
    procedure UpdateQuotes(Customer: Record "18")
    var
        SalesHeader: Record "36";
        Cont: Record "5050";
        SalesLine: Record "37";
    begin
        Cont.SETCURRENTKEY("Company No.");
        Cont.SETRANGE("Company No.","Company No.");

        IF Cont.FIND('-') THEN
          REPEAT
            SalesHeader.RESET;
            SalesHeader.SETCURRENTKEY("Document Type","Sell-to Contact No.");
            SalesHeader.SETRANGE("Document Type",SalesHeader."Document Type"::Quote);
            SalesHeader.SETRANGE("Sell-to Contact No.",Cont."No.");
            IF SalesHeader.FIND('-') THEN
              REPEAT
                SalesHeader."Sell-to Customer No." := Customer."No.";
                SalesHeader."Sell-to Customer Template Code" := '';
                SalesHeader.MODIFY;
                SalesLine.SETRANGE("Document Type",SalesHeader."Document Type");
                SalesLine.SETRANGE("Document No.",SalesHeader."No.");
                IF SalesLine.FIND('-') THEN
                  SalesLine.MODIFYALL("Sell-to Customer No.",SalesHeader."Sell-to Customer No.");
              UNTIL SalesHeader.NEXT = 0;

            SalesHeader.RESET;
            SalesHeader.SETCURRENTKEY("Bill-to Contact No.");
            SalesHeader.SETRANGE("Document Type",SalesHeader."Document Type"::Quote);
            SalesHeader.SETRANGE("Bill-to Contact No.",Cont."No.");
            IF SalesHeader.FIND('-') THEN
              REPEAT
                SalesHeader."Bill-to Customer No." := Customer."No.";
                SalesHeader."Bill-to Customer Template Code" := '';
                SalesHeader."Salesperson Code" := Customer."Salesperson Code";
                SalesHeader.MODIFY;
                SalesLine.SETRANGE("Document Type",SalesHeader."Document Type");
                SalesLine.SETRANGE("Document No.",SalesHeader."No.");
                IF SalesLine.FIND('-') THEN
                  SalesLine.MODIFYALL("Bill-to Customer No.",SalesHeader."Bill-to Customer No.");
              UNTIL SalesHeader.NEXT = 0;
          UNTIL Cont.NEXT = 0;
    end;
 
    procedure GetSalutation(SalutationType: Option Formal,Informal;LanguageCode: Code[10]): Text[260]
    var
        SalutationFormula: Record "5069";
        NamePart: array [5] of Text[50];
        SubStr: Text[30];
        i: Integer;
    begin
        IF NOT SalutationFormula.GET("Salutation Code",LanguageCode,SalutationType) THEN
          ERROR(Text021,LanguageCode,"No.");
        SalutationFormula.TESTFIELD(Salutation);

        CASE SalutationFormula."Name 1" OF
          SalutationFormula."Name 1"::"Job Title":
            NamePart[1] := "Job Title";
          SalutationFormula."Name 1"::"First Name":
            NamePart[1] := "First Name";
          SalutationFormula."Name 1"::"Middle Name":
            NamePart[1] := "Middle Name";
          SalutationFormula."Name 1"::Surname:
            NamePart[1] := Surname;
          SalutationFormula."Name 1"::Initials:
            NamePart[1] := Initials;
          SalutationFormula."Name 1"::"Company Name":
            NamePart[1] := "Company Name";
        END;

        CASE SalutationFormula."Name 2" OF
          SalutationFormula."Name 2"::"Job Title":
            NamePart[2] := "Job Title";
          SalutationFormula."Name 2"::"First Name":
            NamePart[2] := "First Name";
          SalutationFormula."Name 2"::"Middle Name":
            NamePart[2] := "Middle Name";
          SalutationFormula."Name 2"::Surname:
            NamePart[2] := Surname;
          SalutationFormula."Name 2"::Initials:
            NamePart[2] := Initials;
          SalutationFormula."Name 2"::"Company Name":
            NamePart[2] := "Company Name";
        END;

        CASE SalutationFormula."Name 3" OF
          SalutationFormula."Name 3"::"Job Title":
            NamePart[3] := "Job Title";
          SalutationFormula."Name 3"::"First Name":
            NamePart[3] := "First Name";
          SalutationFormula."Name 3"::"Middle Name":
            NamePart[3] := "Middle Name";
          SalutationFormula."Name 3"::Surname:
            NamePart[3] := Surname;
          SalutationFormula."Name 3"::Initials:
            NamePart[3] := Initials;
          SalutationFormula."Name 3"::"Company Name":
            NamePart[3] := "Company Name";
        END;

        CASE SalutationFormula."Name 4" OF
          SalutationFormula."Name 4"::"Job Title":
            NamePart[4] := "Job Title";
          SalutationFormula."Name 4"::"First Name":
            NamePart[4] := "First Name";
          SalutationFormula."Name 4"::"Middle Name":
            NamePart[4] := "Middle Name";
          SalutationFormula."Name 4"::Surname:
            NamePart[4] := Surname;
          SalutationFormula."Name 4"::Initials:
            NamePart[4] := Initials;
          SalutationFormula."Name 4"::"Company Name":
            NamePart[4] := "Company Name";
        END;

        CASE SalutationFormula."Name 5" OF
          SalutationFormula."Name 5"::"Job Title":
            NamePart[5] := "Job Title";
          SalutationFormula."Name 5"::"First Name":
            NamePart[5] := "First Name";
          SalutationFormula."Name 5"::"Middle Name":
            NamePart[5] := "Middle Name";
          SalutationFormula."Name 5"::Surname:
            NamePart[5] := Surname;
          SalutationFormula."Name 5"::Initials:
            NamePart[5] := Initials;
          SalutationFormula."Name 5"::"Company Name":
            NamePart[5] := "Company Name";
        END;

        FOR i := 1 TO 5 DO
          IF NamePart[i] = '' THEN BEGIN
            SubStr := '%' + FORMAT(i) + ' ';
            IF STRPOS(SalutationFormula.Salutation,SubStr) > 0 THEN
              SalutationFormula.Salutation :=
                DELSTR(SalutationFormula.Salutation,STRPOS(SalutationFormula.Salutation,SubStr),3);
          END;

        EXIT(STRSUBSTNO(SalutationFormula.Salutation,NamePart[1],NamePart[2],NamePart[3],NamePart[4],NamePart[5]))
    end;
 
    procedure InheritCompanyToPersonData(Cont: Record "5050";KeepPersonalData: Boolean)
    begin
        "Company Name" := Cont.Name;

        SearchManagement.ParseField(
          "No.","No.","Company Name",SearchWordDetail."Table Name"::Contact,FIELDNO("Company Name"));

        RMSetup.GET;
        IF RMSetup."Inherit Salesperson Code" THEN
          "Salesperson Code" := Cont."Salesperson Code";
        IF RMSetup."Inherit Territory Code" THEN
          "Territory Code" := Cont."Territory Code";
        IF RMSetup."Inherit Country/Region Code" THEN
          "Country/Region Code" := Cont."Country/Region Code";
        IF RMSetup."Inherit Language Code" THEN
          "Language Code" := Cont."Language Code";
        IF RMSetup."Inherit Address Details" AND
          ((NOT KeepPersonalData) OR
           (Cont.Address + Cont."Address 2" + Cont.County + Cont."Post Code" + Cont.City <> ''))
        THEN BEGIN
          Address := Cont.Address;
          "Address 2" := Cont."Address 2";
          "Post Code" := Cont."Post Code";
          City := Cont.City;
          County := Cont.County;
          SearchManagement.ParseField(
            "No.","No.",Address,SearchWordDetail."Table Name"::Contact,FIELDNO(Address));
          SearchManagement.ParseField(
            "No.","No.","Address 2",SearchWordDetail."Table Name"::Contact,FIELDNO("Address 2"));
          SearchManagement.ParseField(
            "No.","No.","Post Code",SearchWordDetail."Table Name"::Contact,FIELDNO("Post Code"));
          SearchManagement.ParseField(
            "No.","No.",City,SearchWordDetail."Table Name"::Contact,FIELDNO(City));
          SearchManagement.ParseField(
            "No.","No.",County,SearchWordDetail."Table Name"::Contact,FIELDNO(County));
        END;
        IF RMSetup."Inherit Communication Details" THEN BEGIN
          IF (Cont."Phone No." <> '') OR NOT KeepPersonalData THEN
            "Phone No." := Cont."Phone No.";
          IF (Cont."Telex No." <> '') OR NOT KeepPersonalData THEN
            "Telex No." := Cont."Telex No.";
          IF (Cont."Fax No." <> '') OR NOT KeepPersonalData THEN
            "Fax No." := Cont."Fax No.";
          IF (Cont."Telex Answer Back" <> '') OR NOT KeepPersonalData THEN
            "Telex Answer Back" := Cont."Telex Answer Back";
          IF (Cont."E-Mail" <> '') OR NOT KeepPersonalData THEN
            VALIDATE("E-Mail",Cont."E-Mail");
          IF (Cont."Home Page" <> '') OR NOT KeepPersonalData THEN
            "Home Page" := Cont."Home Page";
          IF (Cont."Extension No." <> '') OR NOT KeepPersonalData THEN
            "Extension No." := Cont."Extension No.";
          IF (Cont."Mobile Phone No." <> '') OR NOT KeepPersonalData THEN
            "Mobile Phone No." := Cont."Mobile Phone No.";
          IF (Cont.Pager <> '') OR NOT KeepPersonalData THEN
            Pager := Cont.Pager;
          IF (Cont."Correspondence Type" <> "Correspondence Type"::" ") OR NOT KeepPersonalData THEN
            "Correspondence Type" := Cont."Correspondence Type";
          SearchManagement.ParseField(
            "No.","No.","Phone No.",SearchWordDetail."Table Name"::Contact,FIELDNO("Phone No."));
          SearchManagement.ParseField(
            "No.","No.","Telex No.",SearchWordDetail."Table Name"::Contact,FIELDNO("Telex No."));
          SearchManagement.ParseField(
            "No.","No.","Fax No.",SearchWordDetail."Table Name"::Contact,FIELDNO("Fax No."));
          SearchManagement.ParseField(
            "No.","No.","Telex Answer Back",SearchWordDetail."Table Name"::Contact,FIELDNO("Telex Answer Back"));
          SearchManagement.ParseField(
            "No.","No.","E-Mail",SearchWordDetail."Table Name"::Contact,FIELDNO("E-Mail"));
          SearchManagement.ParseField(
            "No.","No.","Home Page",SearchWordDetail."Table Name"::Contact,FIELDNO("Home Page"));
          SearchManagement.ParseField(
            "No.","No.","Mobile Phone No.",SearchWordDetail."Table Name"::Contact,FIELDNO("Mobile Phone No."));
          SearchManagement.ParseField(
            "No.","No.",Pager,SearchWordDetail."Table Name"::Contact,FIELDNO(Pager));
        END;
    end;
 
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean): Boolean
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;
 
    procedure DisplayMap()
    var
        MapPoint: Record "800";
        MapMgt: Codeunit "802";
    begin
        IF MapPoint.FIND('-') THEN
          MapMgt.MakeSelection(DATABASE::Contact,GETPOSITION)
        ELSE MESSAGE(Text033);
    end;
 
    procedure CreateAction(Type: Integer)
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ActionsMgt: Codeunit "99001451";
    begin
        //LS
        //Type: 0 = INSERT, 1 = MODIFY, 2 = DELETE, 3 = RENAME
        //
        RecRef.GETTABLE(Rec);
        xRecRef.GETTABLE(xRec);
        ActionsMgt.CreateActionsByRecRef(RecRef,xRecRef,Type);
        RecRef.CLOSE;
        xRecRef.CLOSE;
    end;
 
    procedure "--DP--"()
    begin
    end;
 
    procedure CreateClient()
    var
        Cust: Record "18";
        ContComp: Record "5050";
        DefaultDim: Record "352";
        DefaultDim2: Record "352";
        PremiseMgtSetup: Record "33016826";
        NoSeriesMgt: Codeunit "396";
        NextNo: Code[20];
    begin
        //DP6.01.01 START
        //Copy of function Create Customer
        TESTFIELD("Company No.");
        PremiseMgtSetup.GET;
        RMSetup.GET;
        RMSetup.TESTFIELD("Bus. Rel. Code for Customers");

        ContBusRel.RESET;
        ContBusRel.SETRANGE("Contact No.","No.");
        ContBusRel.SETRANGE("Link to Table",ContBusRel."Link to Table"::Customer);
        IF ContBusRel.FIND('-') THEN
          ERROR(
            Text019,
            'Client',"No.",ContBusRel.TABLECAPTION,ContBusRel."Link to Table",ContBusRel."No.");

        CLEAR(Cust);
        Cust.SetInsertFromContact(TRUE);
        IF Cust."No." = '' THEN BEGIN
          PremiseMgtSetup.TESTFIELD(PremiseMgtSetup."Client No.");
          NoSeriesMgt.InitSeries(PremiseMgtSetup."Client No.",Cust."No. Series",0D,NextNo,Cust."No. Series");
        END;
        Cust."No." := NextNo;
        Cust."No. Series" := PremiseMgtSetup."Client No.";
        Cust.INSERT(TRUE);
        Cust.SetInsertFromContact(FALSE);

        IF Type = Type::Company THEN
          ContComp := Rec
        ELSE
          ContComp.GET("Company No.");

        ContBusRel."Contact No." := ContComp."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Customers";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::Customer;
        ContBusRel."No." := Cust."No.";
        ContBusRel.INSERT(TRUE);

        UpdateCustVendBank.UpdateCustomer(ContComp,ContBusRel);

        Cust.GET(ContBusRel."No.");
        Cust.VALIDATE("Primary Contact No.","No.");
        Cust.VALIDATE(Name,"Company Name");
        Cust."Client Type" := Cust."Client Type"::Client;
        Cust."Territory Code" := "Territory Code";
        Cust."Currency Code" := ContComp."Currency Code";
        Cust."Country/Region Code" := "Country/Region Code";
        Cust.MODIFY;

        UpdateQuotes(Cust);
        UpdateCustomerSegments(Cust);
        CampaignMgt.ConverttoCustomer(Rec,Cust);
        MESSAGE(Text009,'Client',Cust."No.");
        //DP6.01.01 STOP
    end;
 
    procedure CreateTenant()
    var
        Cust: Record "18";
        ContComp: Record "5050";
        DefaultDim: Record "352";
        DefaultDim2: Record "352";
        PremiseMgtSetup: Record "33016826";
        NoSeriesMgt: Codeunit "396";
        NextNo: Code[20];
    begin
        //DP6.01.01 START
        //Copy of function Create Customer
        TESTFIELD("Company No.");
        PremiseMgtSetup.GET;
        RMSetup.GET;
        RMSetup.TESTFIELD("Bus. Rel. Code for Customers");

        ContBusRel.RESET;
        ContBusRel.SETRANGE("Contact No.","No.");
        ContBusRel.SETRANGE("Link to Table",ContBusRel."Link to Table"::Customer);
        IF ContBusRel.FIND('-') THEN
          ERROR(
            Text019,
            'Tenant',"No.",ContBusRel.TABLECAPTION,ContBusRel."Link to Table",ContBusRel."No.");

        CLEAR(Cust);
        Cust.SetInsertFromContact(TRUE);
        IF Cust."No." = '' THEN BEGIN
          PremiseMgtSetup.TESTFIELD(PremiseMgtSetup."Client No.");
          NoSeriesMgt.InitSeries(PremiseMgtSetup."Client No.",Cust."No. Series",0D,NextNo,Cust."No. Series");
        END;
        Cust."No." := NextNo;
        Cust."No. Series" := PremiseMgtSetup."Client No.";
        Cust.INSERT(TRUE);
        Cust.SetInsertFromContact(FALSE);

        IF Type = Type::Company THEN
          ContComp := Rec
        ELSE
          ContComp.GET("Company No.");

        ContBusRel."Contact No." := ContComp."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Customers";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::Customer;
        ContBusRel."No." := Cust."No.";
        ContBusRel.INSERT(TRUE);

        UpdateCustVendBank.UpdateCustomer(ContComp,ContBusRel);

        Cust.GET(ContBusRel."No.");
        Cust.VALIDATE("Primary Contact No.","No.");
        Cust.VALIDATE(Name,"Company Name");
        Cust."Client Type" := Cust."Client Type"::Tenant;
        Cust."Territory Code" := "Territory Code";
        Cust."Currency Code" := ContComp."Currency Code";
        Cust."Country/Region Code" := "Country/Region Code";
        Cust.MODIFY;

        UpdateQuotes(Cust);
        UpdateCustomerSegments(Cust);
        CampaignMgt.ConverttoCustomer(Rec,Cust);
        MESSAGE(Text009,'Tenant',Cust."No.");
        //DP6.01.01 STOP
    end;
 
    procedure UpdateCustomerSegments(Client: Record "18")
    var
        ContIndustryGrp: Record "5058";
        ContBusinessRelation: Record "5054";
        ContMailingGrp: Record "5056";
        CustIndustryGrp: Record "33016868";
        CustBusinessRelation: Record "33016867";
        CustMailingGrp: Record "33016866";
    begin
        //DP6.01.01 START
        ContIndustryGrp.SETRANGE("Contact No.","No.");
        IF ContIndustryGrp.FINDSET THEN BEGIN
          REPEAT
            CustIndustryGrp.INIT;
            CustIndustryGrp."Client No." := Client."No.";
            CustIndustryGrp.VALIDATE("Industry Group",ContIndustryGrp."Industry Group Code");
            CustIndustryGrp.VALIDATE("Contact No.",ContIndustryGrp."Contact No.");
            CustIndustryGrp.INSERT;
          UNTIL ContIndustryGrp.NEXT = 0;
        END;

        ContBusinessRelation.SETRANGE("Contact No.","No.");
        IF ContBusinessRelation.FINDSET THEN BEGIN
          REPEAT
            CustBusinessRelation.INIT;
            CustBusinessRelation."Client No." := Client."No.";
            CustBusinessRelation.VALIDATE("Business Group",ContBusinessRelation."Business Relation Code");
            CustBusinessRelation.VALIDATE("Contact No.",ContBusinessRelation."Contact No.");
            CustBusinessRelation.INSERT;
          UNTIL ContBusinessRelation.NEXT = 0;
        END;

        ContMailingGrp.SETRANGE("Contact No.","No.");
        IF ContMailingGrp.FINDSET THEN BEGIN
          REPEAT
            CustMailingGrp.INIT;
            CustMailingGrp."Client No." := Client."No.";
            CustMailingGrp.VALIDATE("Mailing Group",ContMailingGrp."Mailing Group Code");
            CustMailingGrp.VALIDATE("Contact No.",ContMailingGrp."Contact No.");
            CustMailingGrp.INSERT;
          UNTIL ContIndustryGrp.NEXT = 0;
        END;
        //DP6.01.01 STOP
    end;
}

