#!/bin/bash
# ~/.spacelift-jwt-config
#cp the script into your home dir as . file
# source ~/.spacelift-jwt-config

# JWT Token (get new token from Postman when expired)
export SPACELIFT_TOKEN="eyJhbGciOiJLTVMiLCJ0eXAiOiJKV1QifQ.eyJhdWQiOlsiaHR0cHM6Ly9pbGdsYWJzLmFwcC5zcGFjZWxpZnQuaW8iXSwiZXhwIjoxNzY3OTg5MzY3LjMwNzAxNCwianRpIjoiMDFLRUgzUTA4QkZOWjY1QkVGSlBTWlZSS04iLCJpYXQiOjE3Njc5NTMzNjcuMzA3MDE0LCJpc3MiOiJhcGkta2V5IiwibmJmIjoxNzY3OTUzMzY3LjMwNzAxNCwic3ViIjoiYXBpOjowMUtDTk42SlA4U0E2OVBSUUZZWUtOSlJaWSIsImFkbSI6dHJ1ZSwiYXZ0IjoiaHR0cHM6Ly93d3cuZ3JhdmF0YXIuY29tL2F2YXRhci83Mzk2ZGIyYzQ4YzM3MmM0YmFlMDQ1MmVkZjNjZTM4ODY1ODllYmQ5NjU1MTEyZjE4YjQzMGEzMmMxMmI1Yzk2LmpwZz9kPXJvYm9oYXNoXHUwMDI2c2l6ZT04MCIsImNpcCI6IjExNC43OS4xNzYuMTgzIiwicHNhIjoiMDFLRUgzUTA5QUI0V0NDRVZKQkJRN0EyWkUiLCJJc01hY2hpbmVVc2VyIjpmYWxzZSwiSXNJbnRlZ3JhdGlvbiI6ZmFsc2UsInN1YmRvbWFpbiI6ImlsZ2xhYnMiLCJmdWxsX25hbWUiOiJncmFwaHFsLWFwaS1rZXlzIn0.eZ/cI27GbPtiIBmcCgLWhyAZTAP+GTZ/ryMhI2oLH3vycXCG39TBy4OlIRozJc+FZumlX58iqZ0NjSkhRYmftHLOeztDIB5CCfrl/+2f/2bqH66i5GIMLGw8L3N1VZGIV+lexfsyVdKE1pocasOq95mlnv+zfMuTJIeIdOBlhBlJhYNZYJ8I2BFVn/07CPmTKyNjzkr8kNn2/t5HQT5cVVr5bBaTlaCWWLDlbfel8VTzwDVMTWkECN8zvF689ak8hjptR/0c9iZ/Jc4kXzDqym8INkvI49caDOFAryFfyD73hrUvaoceKvYxZPzfOA4NpwgmOK6jURT4kMF3a3p7WFSxpfrrCKQHYEOZQqBhI8yUq7dy9phHGB8Da4x43Euyu/rYXmOEqR+xfsp4+5xiw9mlqX/a/bdTeW/mARLRFVcdut8vwTy+gRxL5NZYZPvZ08FuS/DtSm3dY9giul1VbCV2c5KCsNMga+kZT8Ck2pTG/J0jngDAHcoJso8Hla4PjTAY8WwPlIVh6Ta0fEReiUlFdqq2Ea/Eaz1qQz5LaaE2joldRPXxIuIpQHjl1+exsNzYF/Za5Uy8U96+V7LXaVXkHnuvmeTMZj8mL9Rnw0q5IhX6B1Bs5K43bYOxJMdj67E7hOAukCHciE5tykb2r49blExs1Tlcyj8iVYJkNA0="

export SPACELIFT_ENDPOINT="https://ilglabs.app.spacelift.io/graphql"


export SPACELIFT_API_KEY_ID="01KCNN6JP8SA69PRQFYYKNJRZY"
export SPACELIFT_API_KEY_SECRET="d1a70bc723c2ea6aa84a626daf44429200be97fe530f2a2111d8431329da43a9"

# Helper aliases
alias spacelift-test='curl -s -X POST "$SPACELIFT_ENDPOINT" -H "Authorization: Bearer $SPACELIFT_TOKEN" -H "Content-Type: application/json" -d "{\"query\":\"query{stacks{id name state}}\"}" | jq .'
alias spacelift-runs='curl -s -X POST "$SPACELIFT_ENDPOINT" -H "Authorization: Bearer $SPACELIFT_TOKEN" -H "Content-Type: application/json" -d "{\"query\":\"query{stack(id:\\\"ec2-demo-stack\\\"){runs{id state type}}}\"}" | jq .'~                                                                
