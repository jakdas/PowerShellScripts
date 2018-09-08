function get-Parameter($parameterName) {

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$font = New-Object System.Drawing.Font("Times New Roman",12,[System.Drawing.FontStyle]::Regular)

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Data Entry Form'
$form.Size = New-Object System.Drawing.Size(900,400)
$form.StartPosition = 'CenterScreen'
$form.Font = $font
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(150,250)
$OKButton.Size = New-Object System.Drawing.Size(200,60)
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(500,250)
$CancelButton.Size = New-Object System.Drawing.Size(200,60)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(100,80)
$label.Size = New-Object System.Drawing.Size(750,100)
$label.autosize = $true
$label.Text = $parameterName+":"
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.font = $font
$textBox.autosize = $true
$textBox.Location = New-Object System.Drawing.Point(100,150)
$textBox.Size = New-Object System.Drawing.Size(650,100)
$form.Controls.Add($textBox)

$form.Topmost = $true

$form.Add_Shown({$textBox.Select()})
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x = $textBox.Text
    $x
}

}