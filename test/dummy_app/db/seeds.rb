# Clear existing data
puts "Clearing existing data..."
Loan.destroy_all
BookCopy.destroy_all
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
  Book.create!(
    title: "Pride and Prejudice",
    isbn: "978-0-14-143951-8",
    publication_year: 1813,
    pages: 432,
    description: "A romantic novel of manners",
    price: 12.99,
    author: authors[0]
  ),
  Book.create!(
    title: "1984",
    isbn: "978-0-452-28423-4",
    publication_year: 1949,
    pages: 328,
    description: "A dystopian social science fiction novel",
    price: 15.99,
    author: authors[1]
  ),
  Book.create!(
    title: "Beloved",
    isbn: "978-1-4000-3341-6",
    publication_year: 1987,
    pages: 324,
    description: "A novel about the aftermath of slavery",
    price: 16.99,
    author: authors[2]
  ),
  Book.create!(
    title: "Norwegian Wood",
    isbn: "978-0-375-70461-8",
    publication_year: 1987,
    pages: 296,
    description: "A nostalgic story of loss and sexuality",
    price: 14.99,
    author: authors[3]
  ),
  Book.create!(
    title: "Kafka on the Shore",
    isbn: "978-1-4000-7927-8",
    publication_year: 2002,
    pages: 480,
    description: "A metaphysical reality novel",
    price: 16.99,
    author: authors[3]
  ),
  Book.create!(
    title: "Americanah",
    isbn: "978-0-307-45592-7",
    publication_year: 2013,
    pages: 477,
    description: "A novel about race, identity, and love",
    price: 17.99,
    author: authors[4]
  ),
  Book.create!(
    title: "Half of a Yellow Sun",
    isbn: "978-1-4000-4416-0",
    publication_year: 2006,
    pages: 448,
    description: "A novel set during the Nigerian Civil War",
    price: 16.99,
    author: authors[4]
  ),
  Book.create!(
    title: "Animal Farm",
    isbn: "978-0-452-28424-1",
    publication_year: 1945,
    pages: 112,
    description: "An allegorical novella about Stalinism",
    price: 11.99,
    author: authors[1]
  )
]

puts "Creating book copies..."
book_copies = []

# Create multiple copies for each book across different libraries
# Pride and Prejudice - 3 copies across 2 libraries
book_copies << BookCopy.create!(book: books[0], library: libraries[0], rfid: "RFID-PPR-001", available: true)
book_copies << BookCopy.create!(book: books[0], library: libraries[0], rfid: "RFID-PPR-002", available: true)
book_copies << BookCopy.create!(book: books[0], library: libraries[1], rfid: "RFID-PPR-003", available: true)

# 1984 - 4 copies (one will be loaned out)
book_copies << BookCopy.create!(book: books[1], library: libraries[0], rfid: "RFID-1984-001", available: false)
book_copies << BookCopy.create!(book: books[1], library: libraries[0], rfid: "RFID-1984-002", available: true)
book_copies << BookCopy.create!(book: books[1], library: libraries[1], rfid: "RFID-1984-003", available: true)
book_copies << BookCopy.create!(book: books[1], library: libraries[2], rfid: "RFID-1984-004", available: true)

# Beloved - 2 copies
book_copies << BookCopy.create!(book: books[2], library: libraries[0], rfid: "RFID-BLV-001", available: true)
book_copies << BookCopy.create!(book: books[2], library: libraries[2], rfid: "RFID-BLV-002", available: true)

# Norwegian Wood - 2 copies
book_copies << BookCopy.create!(book: books[3], library: libraries[1], rfid: "RFID-NW-001", available: true)
book_copies << BookCopy.create!(book: books[3], library: libraries[1], rfid: "RFID-NW-002", available: true)

# Kafka on the Shore - 2 copies
book_copies << BookCopy.create!(book: books[4], library: libraries[1], rfid: "RFID-KOS-001", available: true)
book_copies << BookCopy.create!(book: books[4], library: libraries[2], rfid: "RFID-KOS-002", available: true)

# Americanah - 2 copies (one will be loaned out)
book_copies << BookCopy.create!(book: books[5], library: libraries[2], rfid: "RFID-AMR-001", available: false)
book_copies << BookCopy.create!(book: books[5], library: libraries[2], rfid: "RFID-AMR-002", available: true)

# Half of a Yellow Sun - 2 copies
book_copies << BookCopy.create!(book: books[6], library: libraries[2], rfid: "RFID-HYS-001", available: true)
book_copies << BookCopy.create!(book: books[6], library: libraries[0], rfid: "RFID-HYS-002", available: true)

# Animal Farm - 3 copies
book_copies << BookCopy.create!(book: books[7], library: libraries[2], rfid: "RFID-AF-001", available: true)
book_copies << BookCopy.create!(book: books[7], library: libraries[0], rfid: "RFID-AF-002", available: true)
book_copies << BookCopy.create!(book: books[7], library: libraries[1], rfid: "RFID-AF-003", available: true)

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
# 1984 copy 1 - checked out to Alice
Loan.create!(
  book_copy: book_copies[3], # RFID-1984-001
  member: members[0], # Alice
  due_date: Date.today + 14.days,
  status: 'active'
)

# Americanah copy 1 - checked out to Frank
Loan.create!(
  book_copy: book_copies[13], # RFID-AMR-001
  member: members[5], # Frank
  due_date: Date.today + 7.days,
  status: 'active'
)

# Pride and Prejudice copy 1 - returned by Bob
Loan.create!(
  book_copy: book_copies[0], # RFID-PPR-001
  member: members[1], # Bob
  due_date: Date.today - 30.days,
  returned_at: DateTime.now - 3.days,
  status: 'returned'
)

# Beloved copy 1 - overdue for Carol
Loan.create!(
  book_copy: book_copies[7], # RFID-BLV-001
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
puts "  Book Copies: #{BookCopy.count}"
puts "  Tags: #{Tag.count}"
puts "  Members: #{Member.count}"
puts "  Profiles: #{Profile.count}"
puts "  Loans: #{Loan.count}"
puts "  Librarians: #{Librarian.count}"
puts "="*60
puts "\nRun 'rails server' and navigate to http://localhost:3000"
puts "="*60
