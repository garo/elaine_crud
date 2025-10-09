# Clear existing data
puts "Clearing existing data..."
Loan.destroy_all
Profile.destroy_all
Book.destroy_all
Tag.destroy_all
Member.destroy_all
Librarian.destroy_all
Author.destroy_all
Library.destroy_all

puts "Creating libraries..."
libraries = [
  Library.create!(
    name: "Central City Library",
    city: "New York",
    state: "NY",
    phone: "212-555-0100",
    email: "contact@centralcity.lib",
    established_date: Date.new(1895, 6, 15)
  ),
  Library.create!(
    name: "Riverside Public Library",
    city: "Portland",
    state: "OR",
    phone: "503-555-0200",
    email: "info@riverside.lib",
    established_date: Date.new(1920, 3, 10)
  ),
  Library.create!(
    name: "Oakwood Community Library",
    city: "Austin",
    state: "TX",
    phone: "512-555-0300",
    email: "hello@oakwood.lib",
    established_date: Date.new(1965, 9, 1)
  )
]

puts "Creating authors..."
authors = [
  Author.create!(
    name: "Jane Austen",
    biography: "English novelist known for her social commentary and wit",
    birth_year: 1775,
    country: "England",
    active: false
  ),
  Author.create!(
    name: "George Orwell",
    biography: "English novelist and essayist, journalist and critic",
    birth_year: 1903,
    country: "England",
    active: false
  ),
  Author.create!(
    name: "Toni Morrison",
    biography: "American novelist noted for her examination of black experience",
    birth_year: 1931,
    country: "United States",
    active: false
  ),
  Author.create!(
    name: "Haruki Murakami",
    biography: "Contemporary Japanese writer known for surrealist fiction",
    birth_year: 1949,
    country: "Japan",
    active: true
  ),
  Author.create!(
    name: "Chimamanda Ngozi Adichie",
    biography: "Nigerian writer and novelist",
    birth_year: 1977,
    country: "Nigeria",
    active: true
  )
]

puts "Creating tags..."
tags = [
  Tag.create!(name: "Fiction", color: "#3B82F6"),
  Tag.create!(name: "Non-Fiction", color: "#10B981"),
  Tag.create!(name: "Science Fiction", color: "#8B5CF6"),
  Tag.create!(name: "Mystery", color: "#F59E0B"),
  Tag.create!(name: "Romance", color: "#EC4899"),
  Tag.create!(name: "Award Winner", color: "#EF4444"),
  Tag.create!(name: "Bestseller", color: "#14B8A6"),
  Tag.create!(name: "Classic", color: "#6366F1"),
  Tag.create!(name: "New Release", color: "#84CC16"),
  Tag.create!(name: "Dystopian", color: "#64748B")
]

puts "Creating books..."
books = [
  # Central City Library
  Book.create!(
    title: "Pride and Prejudice",
    isbn: "978-0-14-143951-8",
    publication_year: 1813,
    pages: 432,
    description: "A romantic novel of manners",
    available: true,
    price: 12.99,
    author: authors[0],
    library: libraries[0]
  ),
  Book.create!(
    title: "1984",
    isbn: "978-0-452-28423-4",
    publication_year: 1949,
    pages: 328,
    description: "A dystopian social science fiction novel",
    available: false,
    price: 15.99,
    author: authors[1],
    library: libraries[0]
  ),
  Book.create!(
    title: "Beloved",
    isbn: "978-1-4000-3341-6",
    publication_year: 1987,
    pages: 324,
    description: "A novel about the aftermath of slavery",
    available: true,
    price: 16.99,
    author: authors[2],
    library: libraries[0]
  ),

  # Riverside Library
  Book.create!(
    title: "Norwegian Wood",
    isbn: "978-0-375-70461-8",
    publication_year: 1987,
    pages: 296,
    description: "A nostalgic story of loss and sexuality",
    available: true,
    price: 14.99,
    author: authors[3],
    library: libraries[1]
  ),
  Book.create!(
    title: "Kafka on the Shore",
    isbn: "978-1-4000-7927-8",
    publication_year: 2002,
    pages: 480,
    description: "A metaphysical reality novel",
    available: true,
    price: 16.99,
    author: authors[3],
    library: libraries[1]
  ),

  # Oakwood Library
  Book.create!(
    title: "Americanah",
    isbn: "978-0-307-45592-7",
    publication_year: 2013,
    pages: 477,
    description: "A novel about race, identity, and love",
    available: false,
    price: 17.99,
    author: authors[4],
    library: libraries[2]
  ),
  Book.create!(
    title: "Half of a Yellow Sun",
    isbn: "978-1-4000-4416-0",
    publication_year: 2006,
    pages: 448,
    description: "A novel set during the Nigerian Civil War",
    available: true,
    price: 16.99,
    author: authors[4],
    library: libraries[2]
  ),
  Book.create!(
    title: "Animal Farm",
    isbn: "978-0-452-28424-1",
    publication_year: 1945,
    pages: 112,
    description: "An allegorical novella about Stalinism",
    available: true,
    price: 11.99,
    author: authors[1],
    library: libraries[2]
  )
]

puts "Creating members..."
members = [
  # Central City members
  Member.create!(
    name: "Alice Johnson",
    email: "alice.j@email.com",
    phone: "212-555-1001",
    membership_type: "Premium",
    joined_at: Date.new(2020, 1, 15),
    active: true,
    library: libraries[0]
  ),
  Member.create!(
    name: "Bob Martinez",
    email: "bob.m@email.com",
    phone: "212-555-1002",
    membership_type: "Standard",
    joined_at: Date.new(2021, 6, 20),
    active: true,
    library: libraries[0]
  ),
  Member.create!(
    name: "Carol White",
    email: "carol.w@email.com",
    phone: "212-555-1003",
    membership_type: "Student",
    joined_at: Date.new(2023, 9, 1),
    active: true,
    library: libraries[0]
  ),

  # Riverside members
  Member.create!(
    name: "David Chen",
    email: "david.c@email.com",
    phone: "503-555-2001",
    membership_type: "Premium",
    joined_at: Date.new(2019, 3, 10),
    active: true,
    library: libraries[1]
  ),
  Member.create!(
    name: "Emma Wilson",
    email: "emma.w@email.com",
    phone: "503-555-2002",
    membership_type: "Senior",
    joined_at: Date.new(2018, 11, 5),
    active: true,
    library: libraries[1]
  ),

  # Oakwood members
  Member.create!(
    name: "Frank Brown",
    email: "frank.b@email.com",
    phone: "512-555-3001",
    membership_type: "Standard",
    joined_at: Date.new(2022, 4, 12),
    active: true,
    library: libraries[2]
  )
]

puts "Creating loans..."
Loan.create!(
  book: books[1], # 1984 (checked out)
  member: members[0], # Alice
  due_date: Date.today + 14.days,
  status: 'active'
)

Loan.create!(
  book: books[5], # Americanah (checked out)
  member: members[5], # Frank
  due_date: Date.today + 7.days,
  status: 'active'
)

Loan.create!(
  book: books[0], # Pride and Prejudice (returned)
  member: members[1], # Bob
  due_date: Date.today - 30.days,
  returned_at: DateTime.now - 3.days,
  status: 'returned'
)

Loan.create!(
  book: books[2], # Beloved (overdue)
  member: members[2], # Carol
  due_date: Date.today - 5.days,
  status: 'overdue'
)

puts "Creating librarians..."
Librarian.create!(
  name: "Sarah Thompson",
  email: "s.thompson@centralcity.lib",
  role: "Manager",
  hire_date: Date.new(2010, 5, 1),
  salary: 65000,
  library: libraries[0]
)

Librarian.create!(
  name: "Michael Rodriguez",
  email: "m.rodriguez@centralcity.lib",
  role: "Assistant",
  hire_date: Date.new(2015, 9, 15),
  salary: 48000,
  library: libraries[0]
)

Librarian.create!(
  name: "Jennifer Lee",
  email: "j.lee@riverside.lib",
  role: "Manager",
  hire_date: Date.new(2012, 3, 20),
  salary: 62000,
  library: libraries[1]
)

Librarian.create!(
  name: "Tom Anderson",
  email: "t.anderson@riverside.lib",
  role: "Archivist",
  hire_date: Date.new(2018, 7, 1),
  salary: 52000,
  library: libraries[1]
)

Librarian.create!(
  name: "Maria Garcia",
  email: "m.garcia@oakwood.lib",
  role: "Manager",
  hire_date: Date.new(2016, 1, 10),
  salary: 60000,
  library: libraries[2]
)

puts "Creating profiles..."
Profile.create!(
  member: members[0], # Alice
  bio: "Avid reader of classic literature and contemporary fiction. Member since 2020.",
  avatar_url: "https://i.pravatar.cc/150?img=1"
)

Profile.create!(
  member: members[1], # Bob
  bio: "Science fiction enthusiast and occasional poetry reader.",
  avatar_url: "https://i.pravatar.cc/150?img=12"
)

Profile.create!(
  member: members[3], # David
  bio: "Literary fiction lover with a special interest in international authors.",
  avatar_url: "https://i.pravatar.cc/150?img=33"
)

puts "Assigning tags to books..."
# Pride and Prejudice - Fiction, Romance, Classic
books[0].tags << [tags[0], tags[4], tags[7]]

# 1984 - Fiction, Science Fiction, Dystopian, Classic, Award Winner
books[1].tags << [tags[0], tags[2], tags[9], tags[7], tags[5]]

# To Kill a Mockingbird - Fiction, Classic, Award Winner
books[2].tags << [tags[0], tags[7], tags[5]]

# The Great Gatsby - Fiction, Classic, Romance
books[3].tags << [tags[0], tags[7], tags[4]]

# Brave New World - Science Fiction, Dystopian, Classic
books[4].tags << [tags[2], tags[9], tags[7]]

# The Catcher in the Rye - Fiction, Classic
books[5].tags << [tags[0], tags[7]]

# Sapiens - Non-Fiction, Bestseller, New Release
books[6].tags << [tags[1], tags[6], tags[8]]

# Half of a Yellow Sun - Fiction, Award Winner
books[7].tags << [tags[0], tags[5]]

puts "\n" + "="*60
puts "Seed data created successfully!"
puts "="*60
puts "Summary:"
puts "  Libraries: #{Library.count}"
puts "  Authors: #{Author.count}"
puts "  Books: #{Book.count}"
puts "  Tags: #{Tag.count}"
puts "  Members: #{Member.count}"
puts "  Profiles: #{Profile.count}"
puts "  Loans: #{Loan.count}"
puts "  Librarians: #{Librarian.count}"
puts "="*60
puts "\nRun 'rails server' and navigate to http://localhost:3000"
puts "="*60
