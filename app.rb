require 'sinatra'
require 'sqlite3'

# метод с инициальзацией БД
def init_db 
	@db = SQLite3::Database.new './db/leprosorium.db'
	@db.results_as_hash = true
end

before do
	init_db
end

configure do
	init_db
	# таблица с постами:
	@db.execute 'CREATE TABLE IF NOT EXISTS Posts 
	(id INTEGER PRIMARY KEY AUTOINCREMENT, created_date DATE, author TEXT, content TEXT)'
	# таблица с комментами к постам(post_id это id поста в таблице Posts):
	@db.execute 'CREATE TABLE IF NOT EXISTS Comments 
	(id INTEGER PRIMARY KEY AUTOINCREMENT, created_date DATE, content TEXT, post_id INTEGER)'	
end

# главная страница, на ней отображаемвсе написанные ранее посты
get '/' do
	@results = @db.execute 'SELECT * FROM Posts ORDER BY id DESC'
	erb :index			
end

# страница для создания нового поста
get '/new' do
	erb :new
end

post '/new' do
	content = params[:content]
	author = params[:author]

	if content.size <= 0
		@error = 'Введите текст'
		return erb :new
	end 

	@db.execute 'INSERT INTO Posts 
	(content, created_date, author) VALUES (?, datetime(), ?)', [content, author]

	redirect to '/'
end

# метод для присвоения запросов из БД о посте и комментариям к нему в переменные для видов:
def add_post_with_id_from_link_and_comments_for_it_from_db(post_id)
	@row = (@db.execute 'SELECT * FROM Posts WHERE id = ?', [post_id])[0] # в массиве 1 элемент
	@comments = @db.execute 'SELECT * FROM Comments WHERE post_id = ? ORDER BY id', [post_id]
end

# страницы отдельных постов и коментариев к ним
get '/details/:post_id' do
	post_id = params[:post_id]
	add_post_with_id_from_link_and_comments_for_it_from_db(post_id)
	erb :details
end

post '/details/:post_id' do
	post_id = params[:post_id]

	content = params[:content]

	if content.size <= 0
		@error = 'Введите текст комментария'
		add_post_with_id_from_link_and_comments_for_it_from_db(post_id)
		return erb :details
	end

  @db.execute('INSERT INTO Comments
	(content, created_date, post_id) VALUES (?, datetime(), ?)', [content, post_id])

	redirect to ('/details/' + post_id)
end