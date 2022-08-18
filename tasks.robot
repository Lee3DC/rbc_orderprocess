*** Settings ***
Documentation       Download the orders file
...                 Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RSB
    ${configs}=    Init Settings
    ${secret}=    Get Secret    op_credentials
    Directory Cleanup    ${configs}
    Open Available Browser    ${secret}[homeURL]    headless=${FALSE}    maximized=${TRUE}
    ${orders}=    Download Orders    ${secret}[csvURL]    ${secret}[excelPath]
    FOR    ${order}    IN    @{orders}
        Click Element    alias:ButtonYep
        Fill The Form    ${order}
        Wait Until Keyword Succeeds    5x    1s    Submit Order
        ${pdf_file}=    Store Receipt Pdf    ${order}[Order number]    ${configs}[receiptsPath]
        ${ss_file}=    Take Screenshot    ${order}[Order number]    ${configs}[screenshotPath]
        Embed Screenshot    ${ss_file}    ${pdf_file}
        Click Element    alias:OrderAnother
    END
    Zip File    ${configs}[receiptsPath]    ${configs}[zipPath]

Test
    ${secret}=    Get Secret    op_credentials
    Log    ${secret}[receiptPath]


*** Keywords ***
Download Orders
    [Documentation]    Download and read the orders file
    [Arguments]    ${in_URL}    ${in_excelPath}
    Download    ${in_URL}    ${in_excelPath}    overwrite=${TRUE}
    ${table}=    Read table from CSV    ${in_excelPath}
    RETURN    @{table}

Fill The Form
    [Arguments]    ${robot}
    Wait Until Page Contains Element    alias:ButtonOrder
    Select From List By Value    id:head    ${robot}[Head]
    Select Radio Button    body    ${robot}[Body]
    Input Text    alias:LegLocator    ${robot}[Legs]
    Input Text    alias:AddressLocator    ${robot}[Address]
    Click Element    alias:ButtonPreview

Init Settings
    ${items}=    Create Dictionary
    ...    receiptsPath=${CURDIR}${/}receipts
    ...    screenshotPath=${CURDIR}${/}screenshot
    ...    zipPath=${CURDIR}${/}receipts.zip
    RETURN    ${items}

Submit Order
    [Documentation]    Submit the order
    Sleep    1s
    Click Element    alias:ButtonOrder
    Assert Ordered

Assert Ordered
    Wait Until Page Contains Element    alias:ReceiptLocator

Store Receipt Pdf
    [Documentation]    The robot should save each order HTML receipt as a PDF file
    [Arguments]    ${order_number}    ${receipt_path}
    ${output_pdf}=    Set Variable    ${receipt_path}${/}${order_number}.pdf
    Wait Until Element Is Visible    id:receipt
    ${results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${results_html}    ${output_pdf}
    RETURN    ${output_pdf}

Take Screenshot
    [Documentation]    Capture robot image
    [Arguments]    ${order_number}    ${screenshot_path}
    ${output_ss}=    Set Variable    ${screenshot_path}${/}${order_number}.PNG
    Capture Element Screenshot    alias:RobotPreviewImage    ${output_ss}
    RETURN    ${output_ss}

Embed Screenshot
    [Documentation]    Append image to Pdf
    [Arguments]    ${screenshot_file}    ${pdf_file}
    Open Pdf    ${pdf_file}
    ${items}=    Create List    ${screenshot_file}
    Add Files To Pdf    ${items}    ${pdf_file}    ${TRUE}
    #Close Pdf    ${pdf_file}

Zip File
    [Documentation]    Archive Folder with zip
    [Arguments]    ${receipt_path}    ${zip_file}
    Archive Folder With Zip    ${receipt_path}    ${zip_file}

Directory Cleanup
    [Documentation]    Create if directories is not exist
    ...    And Empty them if exist
    [Arguments]    ${configs}
    Create Directory    ${configs}[receiptsPath]    exist_ok=${TRUE}
    Create Directory    ${configs}[screenshotPath]    exist_ok=${TRUE}
    Empty Directory    ${configs}[receiptsPath]
    Empty Directory    ${configs}[screenshotPath]
    Remove Files    ${configs}[zipPath]    missing_ok=${TRUE}
