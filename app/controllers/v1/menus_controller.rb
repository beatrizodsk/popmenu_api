class V1::MenusController < ApplicationController
  before_action :set_menu, only: %i[show update destroy]

  # GET /restaurants/:restaurant_id/menus or /menus
  def index
    if params[:restaurant_id]
      @restaurant = Restaurant.find(params[:restaurant_id])
      @menus = @restaurant.menus
      render json: @menus, include: :menu_items
    else
      @menus = Menu.all
      render json: @menus, include: :menu_items
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Restaurant not found' }, status: :not_found
  end

  # GET /menus/:id
  def show
    render json: @menu, include: :menu_items
  end

  # POST /restaurants/:restaurant_id/menus or /menus
  def create
    if params[:restaurant_id]
      @restaurant = Restaurant.find(params[:restaurant_id])
      @menu = @restaurant.menus.build(menu_params)
    else
      @menu = Menu.new(menu_params)
    end

    if @menu.save
      render json: @menu, include: :menu_items, status: :created
    else
      render json: { errors: @menu.errors }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Restaurant not found' }, status: :not_found
  end

  # PATCH/PUT /menus/:id
  def update
    if @menu.update(menu_params)
      render json: @menu, include: :menu_items
    else
      render json: { errors: @menu.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /menus/:id
  def destroy
    @menu.destroy
    head :no_content
  end

  private

  def set_menu
    @menu = Menu.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Menu not found' }, status: :not_found
  end

  def menu_params
    params.require(:menu).permit(:name, :restaurant_id)
  end
end
