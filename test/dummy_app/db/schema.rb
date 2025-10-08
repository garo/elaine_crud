# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_08_120747) do
  create_table "authors", force: :cascade do |t|
    t.string "name", null: false
    t.text "biography"
    t.integer "birth_year"
    t.string "country"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_authors_on_name"
  end

  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.string "isbn", null: false
    t.integer "publication_year"
    t.integer "pages"
    t.text "description"
    t.boolean "available", default: true
    t.decimal "price", precision: 10, scale: 2
    t.integer "author_id", null: false
    t.integer "library_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_books_on_author_id"
    t.index ["isbn"], name: "index_books_on_isbn", unique: true
    t.index ["library_id"], name: "index_books_on_library_id"
    t.index ["title"], name: "index_books_on_title"
  end

  create_table "librarians", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "role", null: false
    t.date "hire_date"
    t.decimal "salary", precision: 10, scale: 2
    t.integer "library_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_librarians_on_email"
    t.index ["library_id"], name: "index_librarians_on_library_id"
    t.index ["role"], name: "index_librarians_on_role"
  end

  create_table "libraries", force: :cascade do |t|
    t.string "name", null: false
    t.string "city", null: false
    t.string "state"
    t.string "phone"
    t.string "email"
    t.date "established_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_libraries_on_name"
  end

  create_table "loans", force: :cascade do |t|
    t.date "due_date", null: false
    t.datetime "returned_at"
    t.string "status", default: "pending", null: false
    t.integer "book_id", null: false
    t.integer "member_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_loans_on_book_id"
    t.index ["due_date"], name: "index_loans_on_due_date"
    t.index ["member_id"], name: "index_loans_on_member_id"
    t.index ["status"], name: "index_loans_on_status"
  end

  create_table "members", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "membership_type", null: false
    t.date "joined_at"
    t.boolean "active", default: true
    t.integer "library_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_members_on_email"
    t.index ["library_id"], name: "index_members_on_library_id"
    t.index ["membership_type"], name: "index_members_on_membership_type"
  end

  create_table "profiles", force: :cascade do |t|
    t.integer "member_id", null: false
    t.text "bio"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_profiles_on_member_id"
  end

  add_foreign_key "books", "authors"
  add_foreign_key "books", "libraries"
  add_foreign_key "librarians", "libraries"
  add_foreign_key "loans", "books"
  add_foreign_key "loans", "members"
  add_foreign_key "members", "libraries"
  add_foreign_key "profiles", "members"
end
