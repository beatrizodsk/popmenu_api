class V1::MenusController < ApplicationController
  before_action :set_menu, only: %i[show update destroy]

  # GET /menus
  def index
    @menus = Menu.all
    render json: @menus, include: :menu_items
  end

  # GET /menus/:id
  def show
    render json: @menu, include: :menu_items
  end

  # POST /menus
  def create
    @menu = Menu.new(menu_params)

    if @menu.save
      render json: @menu, include: :menu_items, status: :created
    else
      render json: { errors: @menu.errors }, status: :unprocessable_entity
    end
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
    params.require(:menu).permit(:name)
  end
end
