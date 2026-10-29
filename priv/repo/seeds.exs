
# Create a Baseline Organizational Root Node
if !Ash.read!(Timeclock.Organizations.Organization) |> Enum.any?() do
  org = Ash.create!(Timeclock.Organizations.Organization, %{name: "Global Operations Core HQ"})
  
  # Link an initial company with its embedded address specifications
  Ash.create!(Timeclock.Organizations.Company, %{
    name: "Enterprise Solutions Inc",
    organization_id: org.id,
    registration_number: "TAX-ID-MAIN-885",
    address: %{
      street: "123 Technology Way",
      city: "Tucson",
      state: "AZ",
      postal_code: "85701",
      country: "USA"
    }
  })
end

# Establish Baseline Roster Audience Calendar Groups
if !Ash.read!(Timeclock.Calendar.Group) |> Enum.any?() do
  Ash.create!(Timeclock.Calendar.Group, %{
    name: "Global On-Site Staff",
    time_zone: "America/Phoenix",
    workdays: %{"monday" => true, "tuesday" => true, "wednesday" => true, "thursday" => true, "friday" => true}
  })
end
