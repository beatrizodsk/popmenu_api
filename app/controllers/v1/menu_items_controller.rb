class V1::MenuItemsController < ApplicationController
  before_action :set_menu_item, only: %i[show update destroy]

  # GET /menus/:menu_id/menu_items (nested route)
  def index
    if params[:menu_id]
      @menu = Menu.find(params[:menu_id])
      @menu_items = @menu.menu_items
      render json: @menu_items, include: :menus
    else
      @menu_items = MenuItem.all
      render json: @menu_items, include: :menus
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Menu not found' }, status: :not_found
  end

  # GET /menu_items/:id
  def show
    render json: @menu_item, include: :menus
  end

  # POST /menus/:menu_id/menu_items (nested route)
  def create
    if params[:menu_id]
      @menu = Menu.find(params[:menu_id])
      @menu_item = MenuItem.new(menu_item_params)

      if @menu_item.save
        @menu.menu_items << @menu_item
        render json: @menu_item, include: :menus, status: :created
      else
        render json: { errors: @menu_item.errors }, status: :unprocessable_entity
      end
    else
      @menu_item = MenuItem.new(menu_item_params)

      if @menu_item.save
        render json: @menu_item, include: :menus, status: :created
      else
        render json: { errors: @menu_item.errors }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Menu not found' }, status: :not_found
  end

  # PATCH/PUT /menu_items/:id
  def update
    if @menu_item.update(menu_item_params)
      render json: @menu_item, include: :menus
    else
      render json: { errors: @menu_item.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /menu_items/:id
  def destroy
    @menu_item.destroy
    head :no_content
  end

  private

  def set_menu_item
    @menu_item = MenuItem.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Menu item not found' }, status: :not_found
  end

  def menu_item_params
    params.require(:menu_item).permit(:name, :price)
  end
end
