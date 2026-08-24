import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FaqService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Public ─────────────────────────────────────────────────────────────────

  async listPublic() {
    const categories = await this.prisma.faqCategory.findMany({
      orderBy: { order: 'asc' },
      include: {
        items: {
          where: { isPublished: true },
          orderBy: { order: 'asc' },
          select: { id: true, question: true, answer: true, order: true },
        },
      },
    });
    return categories.filter((c) => c.items.length > 0);
  }

  // ── Backoffice: catégories ─────────────────────────────────────────────────

  async listCategories() {
    return this.prisma.faqCategory.findMany({
      orderBy: { order: 'asc' },
      include: { _count: { select: { items: true } } },
    });
  }

  async createCategory(data: { name: string; slug: string; order?: number }) {
    return this.prisma.faqCategory.create({ data });
  }

  async updateCategory(id: string, data: { name?: string; slug?: string; order?: number }) {
    await this._categoryOrFail(id);
    return this.prisma.faqCategory.update({ where: { id }, data });
  }

  async deleteCategory(id: string) {
    await this._categoryOrFail(id);
    await this.prisma.faqCategory.delete({ where: { id } });
  }

  // ── Backoffice: items ──────────────────────────────────────────────────────

  async listItems(categoryId?: string) {
    return this.prisma.faqItem.findMany({
      where: categoryId ? { categoryId } : undefined,
      orderBy: [{ categoryId: 'asc' }, { order: 'asc' }],
      include: { category: { select: { name: true } } },
    });
  }

  async createItem(data: {
    categoryId: string;
    question: string;
    answer: string;
    order?: number;
    isPublished?: boolean;
  }) {
    await this._categoryOrFail(data.categoryId);
    return this.prisma.faqItem.create({ data });
  }

  async updateItem(
    id: string,
    data: { question?: string; answer?: string; order?: number; isPublished?: boolean; categoryId?: string },
  ) {
    await this._itemOrFail(id);
    return this.prisma.faqItem.update({ where: { id }, data });
  }

  async deleteItem(id: string) {
    await this._itemOrFail(id);
    await this.prisma.faqItem.delete({ where: { id } });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  private async _categoryOrFail(id: string) {
    const c = await this.prisma.faqCategory.findUnique({ where: { id } });
    if (!c) throw new NotFoundException(`Catégorie FAQ introuvable: ${id}`);
    return c;
  }

  private async _itemOrFail(id: string) {
    const i = await this.prisma.faqItem.findUnique({ where: { id } });
    if (!i) throw new NotFoundException(`Question FAQ introuvable: ${id}`);
    return i;
  }
}
