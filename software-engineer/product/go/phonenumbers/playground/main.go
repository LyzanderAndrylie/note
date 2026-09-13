package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/nyaruka/phonenumbers/v2"
)

func main() {
	numberToParse := "08123456789"
	defaultRegion := "ID"

	// Parse example
	num, err := phonenumbers.Parse(numberToParse, defaultRegion)
	if err != nil {
		fmt.Printf("Error parsing number: %s\n", err)
		os.Exit(1)
	}

	fmt.Printf("            E164: %s\n", phonenumbers.Format(num, phonenumbers.E164))
	fmt.Printf("National Dialing: %s\n", phonenumbers.Format(num, phonenumbers.NATIONAL))
	fmt.Printf("        National: %d\n", *num.NationalNumber)
	fmt.Printf("         IsValid: %s\n", strconv.FormatBool(phonenumbers.IsValidNumber(num)))

	// Validate example
	fmt.Println("IS POSSIBLE: ", phonenumbers.IsPossibleNumber(num))
	fmt.Println("IS VALID: ", phonenumbers.IsValidNumber(num))
}
