table 5088 "Profile Questionnaire Line"
{
    // DP = changes made by DVS
    // 
    // Code          Date            Name            Description
    // APNT-HR1.0    12.11.13        Sangeeta        Changed Length of Description from 50 to 150 for HR & Payroll Customization.

    Caption = 'Profile Questionnaire Line';
    DataCaptionFields = "Profile Questionnaire Code", Description;
    LookupFormID = Form5149;

    fields
    {
        field(1; "Profile Questionnaire Code"; Code[10])
        {
            Caption = 'Profile Questionnaire Code';
            TableRelation = "Profile Questionnaire Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Question,Answer';
            OptionMembers = Question,Answer;

            trigger OnValidate()
            begin
                CASE Type OF
                    Type::Question:
                        BEGIN
                            CALCFIELDS("No. of Contacts");
                            TESTFIELD("No. of Contacts", 0);
                            TESTFIELD("From Value", 0);
                            TESTFIELD("To Value", 0);
                        END;
                    Type::Answer:
                        BEGIN
                            TESTFIELD("Multiple Answers", FALSE);
                            TESTFIELD("Auto Contact Classification", FALSE);
                            TESTFIELD("Customer Class. Field", 0);
                            TESTFIELD("Vendor Class. Field", 0);
                            TESTFIELD("Contact Class. Field", 0);
                            TESTFIELD("Starting Date Formula", "0DF");
                            TESTFIELD("Ending Date Formula", "0DF");
                            TESTFIELD("Classification Method", 0);
                            TESTFIELD("Sorting Method", 0);
                            TESTFIELD("No. of Decimals", 0);
                        END;
                END;
            end;
        }
        field(4; Description; Text[150])
        {
            Caption = 'Description';
            Description = 'HR1.0';
            NotBlank = true;
        }
        field(5; "Multiple Answers"; Boolean)
        {
            Caption = 'Multiple Answers';

            trigger OnValidate()
            begin
                IF "Multiple Answers" THEN
                    TESTFIELD(Type, Type::Question);
            end;
        }
        field(6; "Auto Contact Classification"; Boolean)
        {
            Caption = 'Auto Contact Classification';

            trigger OnValidate()
            begin
                IF "Auto Contact Classification" THEN
                    TESTFIELD(Type, Type::Question)
                ELSE BEGIN
                    TESTFIELD("Customer Class. Field", "Customer Class. Field"::" ");
                    TESTFIELD("Vendor Class. Field", "Vendor Class. Field"::" ");
                    TESTFIELD("Contact Class. Field", "Contact Class. Field"::" ");
                    TESTFIELD("Starting Date Formula", "0DF");
                    TESTFIELD("Ending Date Formula", "0DF");
                    TESTFIELD("Classification Method", "Classification Method"::" ");
                    TESTFIELD("Sorting Method", "Sorting Method"::" ");
                END;
            end;
        }
        field(7; "Customer Class. Field"; Option)
        {
            Caption = 'Customer Class. Field';
            OptionCaption = ' ,Sales (LCY),Profit (LCY),Sales Frequency (Invoices/Year),Avg. Invoice Amount (LCY),Discount (%),Avg. Overdue (Day)';
            OptionMembers = " ","Sales (LCY)","Profit (LCY)","Sales Frequency (Invoices/Year)","Avg. Invoice Amount (LCY)","Discount (%)","Avg. Overdue (Day)";

            trigger OnValidate()
            begin
                IF "Customer Class. Field" <> "Customer Class. Field"::" " THEN BEGIN
                    TESTFIELD(Type, Type::Question);
                    CLEAR("Vendor Class. Field");
                    CLEAR("Contact Class. Field");
                    IF "Classification Method" = "Classification Method"::" " THEN
                        "Classification Method" := "Classification Method"::"Defined Value";
                END ELSE
                    ResetFields;
            end;
        }
        field(8; "Vendor Class. Field"; Option)
        {
            Caption = 'Vendor Class. Field';
            OptionCaption = ' ,Purchase (LCY),Purchase Frequency (Invoices/Year),Avg. Ticket Size (LCY),Discount (%),Avg. Overdue (Day)';
            OptionMembers = " ","Purchase (LCY)","Purchase Frequency (Invoices/Year)","Avg. Ticket Size (LCY)","Discount (%)","Avg. Overdue (Day)";

            trigger OnValidate()
            begin
                IF "Vendor Class. Field" <> "Vendor Class. Field"::" " THEN BEGIN
                    TESTFIELD(Type, Type::Question);
                    CLEAR("Customer Class. Field");
                    CLEAR("Contact Class. Field");
                    IF "Classification Method" = "Classification Method"::" " THEN
                        "Classification Method" := "Classification Method"::"Defined Value";
                END ELSE
                    ResetFields;
            end;
        }
        field(9; "Contact Class. Field"; Option)
        {
            Caption = 'Contact Class. Field';
            OptionCaption = ' ,Interaction Quantity,Interaction Frequency (No./Year),Avg. Interaction Cost (LCY),Avg. Interaction Duration (Min.),Opportunity Won (%),Rating';
            OptionMembers = " ","Interaction Quantity","Interaction Frequency (No./Year)","Avg. Interaction Cost (LCY)","Avg. Interaction Duration (Min.)","Opportunity Won (%)",Rating;

            trigger OnValidate()
            var
                Rating: Record Rating;
            begin
                IF xRec."Contact Class. Field" = "Contact Class. Field"::Rating THEN BEGIN
                    Rating.SETRANGE("Profile Questionnaire Code", "Profile Questionnaire Code");
                    Rating.SETRANGE("Profile Questionnaire Line No.", "Line No.");
                    IF Rating.FIND('-') THEN
                        IF CONFIRM(Text000, FALSE) THEN
                            Rating.DELETEALL
                        ELSE
                            ERROR(Text001, FIELDCAPTION("Contact Class. Field"));
                END;

                IF "Contact Class. Field" <> "Contact Class. Field"::" " THEN BEGIN
                    TESTFIELD(Type, Type::Question);
                    CLEAR("Customer Class. Field");
                    CLEAR("Vendor Class. Field");
                    IF ("Classification Method" = "Classification Method"::" ") OR
                       ("Contact Class. Field" = "Contact Class. Field"::Rating)
                    THEN BEGIN
                        "Classification Method" := "Classification Method"::"Defined Value";
                        "Sorting Method" := "Sorting Method"::" ";
                    END;
                    IF "Contact Class. Field" = "Contact Class. Field"::Rating THEN BEGIN
                        CLEAR("Starting Date Formula");
                        CLEAR("Ending Date Formula");
                    END;
                END ELSE
                    ResetFields;
            end;
        }
        field(10; "Starting Date Formula"; DateFormula)
        {
            Caption = 'Starting Date Formula';

            trigger OnValidate()
            begin
                IF FORMAT("Starting Date Formula") <> '' THEN
                    TESTFIELD(Type, Type::Question);
            end;
        }
        field(11; "Ending Date Formula"; DateFormula)
        {
            Caption = 'Ending Date Formula';

            trigger OnValidate()
            begin
                IF FORMAT("Ending Date Formula") <> '' THEN
                    TESTFIELD(Type, Type::Question);
            end;
        }
        field(12; "Classification Method"; Option)
        {
            Caption = 'Classification Method';
            OptionCaption = ' ,Defined Value,Percentage of Value,Percentage of Contacts';
            OptionMembers = " ","Defined Value","Percentage of Value","Percentage of Contacts";

            trigger OnValidate()
            begin
                IF "Classification Method" <> "Classification Method"::" " THEN BEGIN
                    TESTFIELD(Type, Type::Question);
                    IF "Classification Method" <> "Classification Method"::"Defined Value" THEN
                        "Sorting Method" := ProfileQuestnLine."Sorting Method"::Descending
                    ELSE
                        "Sorting Method" := ProfileQuestnLine."Sorting Method"::" ";
                END ELSE
                    "Sorting Method" := ProfileQuestnLine."Sorting Method"::" ";
            end;
        }
        field(13; "Sorting Method"; Option)
        {
            Caption = 'Sorting Method';
            OptionCaption = ' ,Descending,Ascending';
            OptionMembers = " ","Descending","Ascending";

            trigger OnValidate()
            begin
                IF "Sorting Method" <> "Sorting Method"::" " THEN
                    TESTFIELD(Type, Type::Question);
            end;
        }
        field(14; "From Value"; Decimal)
        {
            BlankZero = true;
            Caption = 'From Value';
            DecimalPlaces = 0 :;

            trigger OnValidate()
            begin
                IF "From Value" <> 0 THEN
                    TESTFIELD(Type, Type::Answer);
            end;
        }
        field(15; "To Value"; Decimal)
        {
            BlankZero = true;
            Caption = 'To Value';
            DecimalPlaces = 0 :;

            trigger OnValidate()
            begin
                IF "To Value" <> 0 THEN
                    TESTFIELD(Type, Type::Answer);
            end;
        }
        field(16; "No. of Contacts"; Integer)
        {
            BlankZero = true;
            CalcFormula = Count("Contact Profile Answer" WHERE(Profile Questionnaire Code=FIELD(Profile Questionnaire Code),
                                                                Line No.=FIELD(Line No.)));
            Caption = 'No. of Contacts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17;Priority;Option)
        {
            Caption = 'Priority';
            InitValue = Normal;
            OptionCaption = 'Very Low (Hidden),Low,Normal,High,Very High';
            OptionMembers = "Very Low (Hidden)",Low,Normal,High,"Very High";

            trigger OnValidate()
            var
                ContProfileAnswer: Record "Contact Profile Answer";
            begin
                TESTFIELD(Type,Type::Answer);
                ContProfileAnswer.SETCURRENTKEY("Profile Questionnaire Code","Line No.");
                ContProfileAnswer.SETRANGE("Profile Questionnaire Code","Profile Questionnaire Code");
                ContProfileAnswer.SETRANGE("Line No.","Line No.");
                ContProfileAnswer.MODIFYALL("Answer Priority",Priority);
                MODIFY;
            end;
        }
        field(18;"No. of Decimals";Integer)
        {
            Caption = 'No. of Decimals';
            MaxValue = 25;
            MinValue = -25;

            trigger OnValidate()
            begin
                IF "No. of Decimals" <> 0 THEN
                  TESTFIELD(Type,Type::Question);
            end;
        }
        field(19;"Min. % Questions Answered";Decimal)
        {
            Caption = 'Min. % Questions Answered';
            DecimalPlaces = 0:0;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                IF "Min. % Questions Answered" <> 0 THEN BEGIN
                  TESTFIELD(Type,Type::Question);
                  TESTFIELD("Contact Class. Field","Contact Class. Field"::Rating);
                END;
            end;
        }
        field(9501;"Wizard Step";Option)
        {
            Caption = 'Wizard Step';
            Editable = false;
            OptionCaption = ' ,1,2,3,4,5,6';
            OptionMembers = " ","1","2","3","4","5","6";
        }
        field(9502;"Interval Option";Option)
        {
            Caption = 'Interval Option';
            OptionCaption = 'Minimum,Maximum,Interval';
            OptionMembers = Minimum,Maximum,Interval;
        }
        field(9503;"Answer Option";Option)
        {
            Caption = 'Answer Option';
            OptionCaption = 'HighLow,ABC,Custom';
            OptionMembers = HighLow,ABC,Custom;
        }
        field(9504;"Answer Description";Text[50])
        {
            Caption = 'Answer Description';
        }
        field(9505;"Wizard From Value";Decimal)
        {
            BlankZero = true;
            Caption = 'Wizard From Value';
            DecimalPlaces = 0:;

            trigger OnValidate()
            begin
                 IF "From Value" <> 0 THEN
                   TESTFIELD(Type,Type::Answer);
            end;
        }
        field(9506;"Wizard To Value";Decimal)
        {
            BlankZero = true;
            Caption = 'Wizard To Value';
            DecimalPlaces = 0:;

            trigger OnValidate()
            begin
                 IF "To Value" <> 0 THEN
                   TESTFIELD(Type,Type::Answer);
            end;
        }
        field(9707;"Wizard From Line No.";Integer)
        {
            BlankZero = true;
            Caption = 'Wizard From Line No.';

            trigger OnValidate()
            begin
                 IF "To Value" <> 0 THEN
                   TESTFIELD(Type,Type::Answer);
            end;
        }
        field(33016800;"No. of Answers";Integer)
        {
            CalcFormula = Count("Profile Answers" WHERE (Profile Questionnaire Code =FIELD(Profile Questionnaire Code),
                                                         Line No.=FIELD(Line No.)));
            Description = 'DP6.01.01';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33016801;"Room No.";Code[10])
        {
            Description = 'DP6.01.01';
        }
        field(33016802;"Answer Type";Option)
        {
            Description = 'DP6.01.01';
            OptionCaption = 'Check,Text,Number,Boolean,Date';
            OptionMembers = Check,Text,Number,Boolean,Date;
        }
        field(33016803;"Min. Value";Decimal)
        {
            Description = 'DP6.01.01';
        }
        field(33016804;"Max. Value";Decimal)
        {
            Description = 'DP6.01.01';
        }
        field(33016805;"Client No. of Answers";Integer)
        {
            CalcFormula = Count("Client Profile Answer" WHERE (Profile Questionnaire Code =FIELD(Profile Questionnaire Code),
                                                               Line No.=FIELD(Line No.)));
            Description = 'DP6.01.01';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1;"Profile Questionnaire Code","Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Rating: Record Rating;
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        CALCFIELDS("No. of Contacts");
        TESTFIELD("No. of Contacts",0);

        Rating.SETRANGE("Rating Profile Quest. Code","Profile Questionnaire Code");
        Rating.SETRANGE("Rating Profile Quest. Line No.","Line No.");
        IF Rating.FIND('-') THEN
          ERROR(Text002);

        Rating.RESET;
        Rating.SETRANGE("Profile Questionnaire Code","Profile Questionnaire Code");
        Rating.SETRANGE("Profile Questionnaire Line No.","Line No.");
        IF Rating.FIND('-') THEN
          ERROR(Text003,TABLECAPTION);

        IF Type = Type::Question THEN BEGIN
          ProfileQuestionnaireLine.GET("Profile Questionnaire Code","Line No.");
          IF (ProfileQuestionnaireLine.NEXT <> 0) AND
             (ProfileQuestionnaireLine.Type = ProfileQuestnLine.Type::Answer) THEN
            ERROR(Text004,TABLECAPTION);
        END;
    end;

    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        TempProfileLineAnswer: Record "Profile Questionnaire Line" temporary;
        "0DF": DateFormula;
        Text000: Label 'Do you want to delete the rating values?';
        Text001: Label '%1 cannot be changed until the rating value is deleted.';
        Text002: Label 'You cannot delete this line because one or more questions are depending on it.';
        Text003: Label 'You cannot delete this line because one or more rating values exists.';
        Text004: Label 'You cannot delete this question while answers exists.';
        Text005: Label 'Please select for which questionnaire this rating should be created.';
        Text006: Label 'Please describe the rating.';
        Text007: Label 'Please create one or more different answers.';
        Text008: Label 'Please enter which range of points this answer should require.';
        Text009: Label 'High';
        Text010: Label 'Low';
 
    procedure MoveUp()
    var
        UpperProfileQuestnLine: Record "Profile Questionnaire Line";
        LineNo: Integer;
        UpperRecLineNo: Integer;
    begin
        TESTFIELD(Type,Type::Answer);
        UpperProfileQuestnLine.SETRANGE("Profile Questionnaire Code","Profile Questionnaire Code");
        LineNo := "Line No.";
        UpperProfileQuestnLine.GET("Profile Questionnaire Code","Line No.");

        IF UpperProfileQuestnLine.FIND('<') AND
           (UpperProfileQuestnLine.Type = UpperProfileQuestnLine.Type::Answer)
        THEN BEGIN
          UpperRecLineNo := UpperProfileQuestnLine."Line No.";
          RENAME("Profile Questionnaire Code",-1);
          UpperProfileQuestnLine.RENAME("Profile Questionnaire Code",LineNo);
          RENAME("Profile Questionnaire Code",UpperRecLineNo);
        END;
    end;
 
    procedure MoveDown()
    var
        LowerProfileQuestnLine: Record "Profile Questionnaire Line";
        LineNo: Integer;
        LowerRecLineNo: Integer;
    begin
        TESTFIELD(Type,Type::Answer);
        LowerProfileQuestnLine.SETRANGE("Profile Questionnaire Code","Profile Questionnaire Code");
        LineNo := "Line No.";
        LowerProfileQuestnLine.GET("Profile Questionnaire Code","Line No.");

        IF LowerProfileQuestnLine.FIND('>') AND
           (LowerProfileQuestnLine.Type = LowerProfileQuestnLine.Type::Answer)
        THEN BEGIN
          LowerRecLineNo := LowerProfileQuestnLine."Line No.";
          RENAME("Profile Questionnaire Code",-1);
          LowerProfileQuestnLine.RENAME("Profile Questionnaire Code",LineNo);
          RENAME("Profile Questionnaire Code",LowerRecLineNo);
        END;
    end;
 
    procedure Question(): Text[50]
    begin
        ProfileQuestnLine.RESET;
        ProfileQuestnLine.SETRANGE("Profile Questionnaire Code",Rec."Profile Questionnaire Code");
        ProfileQuestnLine.SETFILTER("Line No.",'<%1',Rec."Line No.");
        ProfileQuestnLine.SETRANGE(Type,Type::Question);
        IF ProfileQuestnLine.FIND('+') THEN
          EXIT(ProfileQuestnLine.Description);
    end;
 
    procedure FindQuestionLine() QuestnLineNo: Integer
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
        ProfileQuestnLine.RESET;
        ProfileQuestnLine.SETRANGE("Profile Questionnaire Code","Profile Questionnaire Code");
        ProfileQuestnLine.SETFILTER("Line No.",'<%1',"Line No.");
        ProfileQuestnLine.SETRANGE(Type,Type::Question);
        IF ProfileQuestnLine.FIND('+') THEN
          EXIT(ProfileQuestnLine."Line No.");
    end;
 
    procedure ResetFields()
    begin
        CLEAR("Starting Date Formula");
        CLEAR("Ending Date Formula");
        "Classification Method" := "Classification Method"::" ";
        "Sorting Method" := "Sorting Method"::" ";
        "No. of Decimals" := 0;
        "Min. % Questions Answered" := 0;
    end;
 
    procedure CreateRatingFromProfQuestnLine(var ProfileQuestnLine: Record "Profile Questionnaire Line")
    var
        TempProfileQuestionnaireLine: Record "Profile Questionnaire Line" temporary;
    begin
        INIT;
        "Profile Questionnaire Code" := ProfileQuestnLine."Profile Questionnaire Code";
        StartWizard;
    end;
 
    procedure StartWizard()
    begin
        "Wizard Step" := "Wizard Step"::"1";
        VALIDATE("Auto Contact Classification",TRUE);
        VALIDATE("Contact Class. Field","Contact Class. Field"::Rating);
        INSERT;

        ValidateAnswerOption;
        ValidateIntervalOption;

        FORM.RUNMODAL(FORM::"Create Rating",Rec);
    end;
 
    procedure CheckStatus()
    begin
        CASE "Wizard Step" OF
          "Wizard Step"::"1":
            BEGIN
              IF "Profile Questionnaire Code" = '' THEN
                ERROR(Text005);
              IF Description = '' THEN
                ERROR(Text006);
            END;
          "Wizard Step"::"2":
            BEGIN
              IF TempProfileLineAnswer.COUNT = 0 THEN
                ERROR(Text007);
            END;
          "Wizard Step"::"3":
            IF ("Wizard From Value" = 0) AND ("Wizard To Value" = 0) THEN
              ERROR(Text008);
        END;
    end;
 
    procedure PerformNextWizardStatus()
    begin
        CASE "Wizard Step" OF
          "Wizard Step"::"1":
            "Wizard Step" := "Wizard Step" + 1;
          "Wizard Step"::"2":
            BEGIN
              "Wizard From Line No." := 0;
              "Wizard Step" := "Wizard Step" + 1;
              TempProfileLineAnswer.SETRANGE("Line No.");
              TempProfileLineAnswer.FIND('-');
              SetIntervalOption;
            END;
          "Wizard Step"::"3":
            BEGIN
              TempProfileLineAnswer.SETFILTER("Line No.",'%1..',"Wizard From Line No.");
              TempProfileLineAnswer.FIND('-');
              TempProfileLineAnswer."From Value" := "Wizard From Value";
              TempProfileLineAnswer."To Value" := "Wizard To Value";
              TempProfileLineAnswer.MODIFY;
              IF TempProfileLineAnswer.NEXT <> 0 THEN BEGIN
                TempProfileLineAnswer.SETRANGE("Line No.",TempProfileLineAnswer."Line No.");
                "Wizard From Line No." := TempProfileLineAnswer."Line No.";
                "Wizard From Value" := TempProfileLineAnswer."From Value";
                "Wizard To Value" := TempProfileLineAnswer."To Value";
                SetIntervalOption;
              END ELSE BEGIN
                TempProfileLineAnswer.SETRANGE("Line No.");
                TempProfileLineAnswer.FIND('-');
                "Wizard Step" := "Wizard Step" + 1;
              END;
            END;
        END;
    end;
 
    procedure PerformPrevWizardStatus()
    begin
        CASE "Wizard Step" OF
          "Wizard Step"::"3":
            BEGIN
              TempProfileLineAnswer.SETFILTER("Line No.",'..%1',"Wizard From Line No.");
              IF TempProfileLineAnswer.FIND('+') THEN BEGIN
                TempProfileLineAnswer."From Value" := "Wizard From Value";
                TempProfileLineAnswer."To Value" := "Wizard To Value";
                TempProfileLineAnswer.MODIFY;
              END;
              IF TempProfileLineAnswer.NEXT(-1) <> 0 THEN BEGIN
                "Wizard From Line No." := TempProfileLineAnswer."Line No.";
                "Wizard From Value" := TempProfileLineAnswer."From Value";
                "Wizard To Value" := TempProfileLineAnswer."To Value";
                SetIntervalOption
              END ELSE BEGIN
                TempProfileLineAnswer.SETRANGE("Line No.");
                TempProfileLineAnswer.FIND('-');
                "Wizard Step" := "Wizard Step" - 1;
              END;
            END;
          ELSE
            "Wizard Step" := "Wizard Step" - 1;
        END;
    end;
 
    procedure FinishWizard(): Boolean
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        NextLineNo: Integer;
        QuestionLineNo: Integer;
        ProfileManagement: Codeunit "5059";
    begin
        // RENAME(ProfileQuestionnaireCode);

        ProfileQuestionnaireLine.SETRANGE("Profile Questionnaire Code","Profile Questionnaire Code");
        IF ProfileQuestionnaireLine.FIND('+') THEN
          QuestionLineNo := ProfileQuestionnaireLine."Line No." + 10000
        ELSE
          QuestionLineNo := 10000;

        ProfileQuestionnaireLine := Rec;
        ProfileQuestionnaireLine."Line No." := QuestionLineNo;
        ProfileQuestionnaireLine.INSERT(TRUE);

        NextLineNo := QuestionLineNo;
        IF TempProfileLineAnswer.FIND('-') THEN
          REPEAT
            NextLineNo := NextLineNo + 10000;
            ProfileQuestionnaireLine := TempProfileLineAnswer;
            ProfileQuestionnaireLine."Profile Questionnaire Code" := "Profile Questionnaire Code";
            ProfileQuestionnaireLine."Line No." := NextLineNo;
            ProfileQuestionnaireLine.INSERT(TRUE);
          UNTIL TempProfileLineAnswer.NEXT = 0;

        COMMIT;

        ProfileQuestionnaireLine.GET("Profile Questionnaire Code",QuestionLineNo);
        ProfileManagement.ShowAnswerPoints(ProfileQuestionnaireLine);
    end;
 
    procedure SetIntervalOption()
    begin
        CASE TRUE OF
          (TempProfileLineAnswer."From Value" = 0) AND (TempProfileLineAnswer."To Value" <> 0):
            "Interval Option" := "Interval Option"::Maximum;
          (TempProfileLineAnswer."From Value" <> 0) AND (TempProfileLineAnswer."To Value" = 0):
            "Interval Option" := "Interval Option"::Minimum
          ELSE
            "Interval Option" := "Interval Option"::Interval
        END;

        ValidateIntervalOption;
    end;
 
    procedure ValidateIntervalOption()
    begin
        TempProfileLineAnswer.SETFILTER("Line No.",'%1..',"Wizard From Line No.");
        TempProfileLineAnswer.FIND('-');
        IF "Interval Option" = "Interval Option"::Minimum THEN
          TempProfileLineAnswer."To Value" := 0;
        IF "Interval Option" = "Interval Option"::Maximum THEN
          TempProfileLineAnswer."From Value" := 0;
        TempProfileLineAnswer.MODIFY;
    end;
 
    procedure ValidateAnswerOption()
    begin
        IF "Answer Option" = "Answer Option"::Custom THEN
          EXIT;

        TempProfileLineAnswer.DELETEALL;

        CASE "Answer Option" OF
          "Answer Option"::HighLow:
            BEGIN
              CreateAnswer(Text009);
              CreateAnswer(Text010);
            END;
          "Answer Option"::ABC:
            BEGIN
              CreateAnswer('A');
              CreateAnswer('B');
              CreateAnswer('C');
            END;
        END;
    end;
 
    procedure CreateAnswer(AnswerDescription: Text[50])
    begin
        TempProfileLineAnswer.INIT;
        TempProfileLineAnswer."Line No." := (TempProfileLineAnswer.COUNT + 1) * 10000;
        TempProfileLineAnswer.Type := TempProfileLineAnswer.Type::Answer;
        TempProfileLineAnswer.Description := AnswerDescription;
        TempProfileLineAnswer.INSERT;
    end;
 
    procedure NoOfProfileAnswers(): Decimal
    begin
        EXIT(TempProfileLineAnswer.COUNT);
    end;
 
    procedure ShowAnswers()
    var
        TempProfileLineAnswer2: Record "Profile Questionnaire Line" temporary;
    begin
        IF "Answer Option" <> "Answer Option"::Custom THEN
          IF TempProfileLineAnswer.FIND('-') THEN
            REPEAT
              TempProfileLineAnswer2 := TempProfileLineAnswer;
              TempProfileLineAnswer2.INSERT;
            UNTIL TempProfileLineAnswer.NEXT = 0;

        FORM.RUNMODAL(FORM::"Rating Answers",TempProfileLineAnswer);

        IF "Answer Option" <> "Answer Option"::Custom THEN
          IF TempProfileLineAnswer.COUNT <> TempProfileLineAnswer2.COUNT THEN
            "Answer Option" := "Answer Option"::Custom
          ELSE BEGIN
            IF TempProfileLineAnswer.FIND('-') THEN
              REPEAT
                IF NOT TempProfileLineAnswer2.GET(
                  TempProfileLineAnswer."Profile Questionnaire Code",TempProfileLineAnswer."Line No.")
                THEN
                  "Answer Option" := "Answer Option"::Custom
                ELSE
                  IF TempProfileLineAnswer.Description <> TempProfileLineAnswer2.Description THEN
                    "Answer Option" := "Answer Option"::Custom
              UNTIL (TempProfileLineAnswer.NEXT = 0) OR ("Answer Option" = "Answer Option"::Custom);
          END;
    end;
 
    procedure GetProfileLineAnswerDesc(): Text[100]
    begin
        TempProfileLineAnswer.SETFILTER("Line No.",'%1..',"Wizard From Line No.");
        TempProfileLineAnswer.FIND('-');
        EXIT(TempProfileLineAnswer.Description);
    end;
 
    procedure GetAnswers(var ProfileLineAnswer: Record "Profile Questionnaire Line")
    begin
        TempProfileLineAnswer.RESET;
        ProfileLineAnswer.RESET;
        ProfileLineAnswer.DELETEALL;
        IF TempProfileLineAnswer.FIND('-') THEN
          REPEAT
            ProfileLineAnswer.INIT;
            ProfileLineAnswer := TempProfileLineAnswer;
            ProfileLineAnswer.INSERT;
          UNTIL TempProfileLineAnswer.NEXT = 0;
    end;
}

