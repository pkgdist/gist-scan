function .scanner -d "GH Secrets Scanner"

# apply encrypted .envcrypt secret:
set -gx GH_SCAN_TOKEN (make echo-GH_SCAN_TOKEN)

# scan using terms
./bin/aarch64-apple-darwin/scanner $argv

end
