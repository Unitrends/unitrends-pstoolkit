function Update-UebPsToolkit {
	param()

    iwr https://raw.githubusercontent.com/Unitrends/unitrends-pstoolkit/master/Unitrends/Install.ps1 | iex

}
