class BooksController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show, :reviews]

  # before_filter :set_json_format, except: [:index, :show]
  return_json except: [:index, :show]

  def reviews
    @reviews = Book.find(params[:id]).reviews
  end

  def recommendations
    @recommendations = current_user.received_recommendations
  end

  def index
    @books = Book.all
  end

  def show
    @book = Book.find params[:id]
  end

  def query
    @book_array = Book.where(isbn: params['isbn'])
    @book = Book.where(isbn: params['isbn'])[0]
    @no_book = "no book"
    if @book_array.count == 0
      render json: @no_book.to_json
    elsif @book_array.count != 0
      render json: @book.to_json
    end
  end

  def create
    @book = Book.new create_params.merge(creator: current_user)
    if @book.save
      category_names = params[:book][:categories].split(",")
      category_names.each do |category_name|
        @book.categories << Category.where(name: category_name).first_or_create!
      end
      render :show
    else
      render_invalid @book
    end
  end

  def update
    @book = Book.find params[:id]
    authorize! :edit, @book
    if @book.update update_params
      render :show
    else
      render_invalid @book
    end
  end

  def review
    book = Book.find params[:id]
    @review = book.reviews.new(
      review_params.merge( user: current_user ))
    if @review.save
      render :review
    else
      render_invalid @review
    end
  end

  def recommend
    book = Book.find params[:id]
    @recommendation = book.recommendations.create!(
      recommendation_params.merge( sender: current_user ))
  end

private

  def create_params
    params.require(:book).
      permit(:title, :author, :isbn, :image_url, :description, :category_id).
      merge(created_by: current_user)
  end

  def update_params
    params.require(:book).permit(:title, :author, :isbn, :image_url, :description)
  end

  # N.B. This smells like it should be in a ReviewsController
  def review_params
    params.require(:review).permit(:rating, :text)
  end
  def recommendation_params
    params.require(:recommendation).permit(:text, :recipient_id)
  end
end
