require 'sinatra'
require 'sqlite3'
require 'sinatra/reloader'

# =============================================
# метод с инициальзацией БД
# =============================================
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

# =============================================
# главная страница, на ней отображаемвсе написанные ранее посты
# =============================================
get '/' do	
	redirect to '/posts/1'		
end

# для следующих страниц(по 5 постов)
get '/posts/:page_id' do
	@page_id = params[:page_id]
	offset = (params[:page_id].to_i - 1) * 5
	# номера страниц дя главной страницы
	@page_counter = (@db.execute('SELECT * FROM Posts').size / 5.0).ceil

	@results = @db.execute('SELECT * FROM Posts ORDER BY id DESC LIMIT ?, 5', [offset])
	# запрос для счетчика коментов
	@comment_counter = @db.execute 'SELECT post_id, COUNT(*) AS count FROM Comments GROUP BY post_id' 
	erb :index			
end

# =============================================
# страница для создания нового поста
# =============================================
get '/new' do
	erb :new
end

post '/new' do
	content = params[:content]
	author = params[:author]

	# валидация
	hh = {content: 'Введите текст вашего поста', author: 'Введите ваш никнэйм'}
	if content.size<=0 or author.size<=0
		@error = hh.select{|k,_| params[k]==''}.values.join(', ')
		return erb :new
	end 

	@db.execute 'INSERT INTO Posts 
	(content, created_date, author) VALUES (?, datetime(), ?)', [content, author]

	redirect to '/'
end

# =============================================
# страницы отдельных постов и коментариев к ним
# =============================================

# метод для присвоения запросов из БД о посте и комментариям к нему в переменные для видов:
def add_post_with_id_from_link_and_comments_for_it_from_db(post_id)
	@row = (@db.execute 'SELECT * FROM Posts WHERE id = ?', [post_id])[0] # в массиве 1 элемент
	@comments = @db.execute 'SELECT * FROM Comments WHERE post_id = ? ORDER BY id', [post_id]
end

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